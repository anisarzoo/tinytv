import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/channel.dart';
import '../models/recording.dart';
import 'storage_service.dart';

class RecordingService extends ChangeNotifier {
  final StorageService storage;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Duration _recordingDuration = Duration.zero;
  Duration get recordingDuration => _recordingDuration;

  int _recordingFileSize = 0;
  int get recordingFileSize => _recordingFileSize;

  Channel? _recordingChannel;
  Channel? get recordingChannel => _recordingChannel;

  String? _currentRecordingPath;
  String? get currentRecordingPath => _currentRecordingPath;

  Timer? _durationTimer;
  Timer? _sizeMonitorTimer;
  DateTime? _recordingStartTime;

  http.Client? _httpFallbackClient;
  IOSink? _httpFallbackSink;
  StreamSubscription? _httpStreamSub;

  final List<Recording> _recordings = [];
  List<Recording> get recordings => List.unmodifiable(_recordings);

  RecordingService(this.storage) {
    _loadRecordings();
  }

  void _loadRecordings() {
    final rawList = storage.getSavedRecordingsJson();
    _recordings.clear();
    for (final item in rawList) {
      try {
        final rec = Recording.fromJson(item);
        if (File(rec.filePath).existsSync()) {
          _recordings.add(rec);
        }
      } catch (_) {}
    }
    // Sort newest first
    _recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  Future<Directory> getRecordingsDirectory() async {
    try {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.isNotEmpty) {
          final videosDir = Directory(path.join(userProfile, 'Videos', 'TinyTV'));
          if (!await videosDir.exists()) {
            await videosDir.create(recursive: true);
          }
          return videosDir;
        }
      }

      final appDocs = await getApplicationDocumentsDirectory();
      final dir = Directory(path.join(appDocs.path, 'TinyTV', 'Recordings'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final temp = await getTemporaryDirectory();
      final dir = Directory(path.join(temp.path, 'TinyTV_Recordings'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  Future<bool> startRecording({
    required Channel channel,
    required Player player,
  }) async {
    if (_isRecording) return false;

    try {
      final dir = await getRecordingsDirectory();
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      
      final cleanName = channel.name
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();
      final safeName = cleanName.isEmpty ? 'Channel' : cleanName;
      final fileName = 'TinyTV_${safeName}_$timestamp.ts';
      final targetPath = path.join(dir.path, fileName);

      _currentRecordingPath = targetPath;
      _recordingChannel = channel;
      _recordingStartTime = now;
      _recordingDuration = Duration.zero;
      _recordingFileSize = 0;
      _isRecording = true;

      // Start duration ticker
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_recordingStartTime != null) {
          _recordingDuration = DateTime.now().difference(_recordingStartTime!);
          notifyListeners();
        }
      });

      // Start file size monitor ticker
      _sizeMonitorTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (_currentRecordingPath != null) {
          try {
            final f = File(_currentRecordingPath!);
            if (f.existsSync()) {
              _recordingFileSize = f.lengthSync();
              notifyListeners();
            }
          } catch (_) {}
        }
      });

      // 1. Primary MPV stream-record
      bool mpvSuccess = false;
      try {
        await (player.platform as dynamic).setProperty('stream-record', targetPath);
        mpvSuccess = true;
      } catch (e) {
        debugPrint('[RecordingService] MPV setProperty stream-record failed: $e');
      }

      // 2. Auxiliary HTTP stream fallback if MPV setProperty failed
      if (!mpvSuccess) {
        _startHttpFallback(channel.url, targetPath);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[RecordingService] startRecording error: $e');
      _cleanupTimers();
      _isRecording = false;
      notifyListeners();
      return false;
    }
  }

  void _startHttpFallback(String url, String targetPath) {
    try {
      _httpFallbackClient = http.Client();
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri)
        ..headers.addAll({
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': '*/*',
        });

      _httpFallbackClient!.send(request).then((response) {
        if (response.statusCode == 200) {
          final file = File(targetPath);
          _httpFallbackSink = file.openWrite();
          _httpStreamSub = response.stream.listen(
            (chunk) {
              _httpFallbackSink?.add(chunk);
              _recordingFileSize += chunk.length;
            },
            onError: (err) {
              debugPrint('[RecordingService] HTTP fallback error: $err');
            },
          );
        }
      }).catchError((err) {
        debugPrint('[RecordingService] HTTP fallback request error: $err');
      });
    } catch (e) {
      debugPrint('[RecordingService] HTTP fallback init error: $e');
    }
  }

  Future<Recording?> stopRecording({required Player player}) async {
    if (!_isRecording) return null;

    final targetPath = _currentRecordingPath;
    final channel = _recordingChannel;
    final startTime = _recordingStartTime ?? DateTime.now();
    final durationSecs = _recordingDuration.inSeconds;

    // Stop MPV stream-record
    try {
      await (player.platform as dynamic).setProperty('stream-record', '');
    } catch (e) {
      debugPrint('[RecordingService] stop MPV error: $e');
    }

    // Stop HTTP Fallback if active
    await _stopHttpFallback();

    _cleanupTimers();
    _isRecording = false;
    _recordingChannel = null;
    _currentRecordingPath = null;
    _recordingStartTime = null;

    // Small delay for OS disk flush
    await Future.delayed(const Duration(milliseconds: 300));

    Recording? savedRecording;
    if (targetPath != null && channel != null) {
      final f = File(targetPath);
      if (f.existsSync() && f.lengthSync() > 0) {
        final fileSize = f.lengthSync();
        savedRecording = Recording(
          id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
          channelName: channel.name,
          channelLogo: channel.logo,
          filePath: targetPath,
          recordedAt: startTime,
          durationSeconds: durationSecs > 0 ? durationSecs : 1,
          fileSizeBytes: fileSize,
        );

        _recordings.insert(0, savedRecording);
        await _persistRecordings();
      } else if (f.existsSync()) {
        // Remove empty 0-byte file
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }

    notifyListeners();
    return savedRecording;
  }

  Future<void> _stopHttpFallback() async {
    await _httpStreamSub?.cancel();
    _httpStreamSub = null;
    await _httpFallbackSink?.flush();
    await _httpFallbackSink?.close();
    _httpFallbackSink = null;
    _httpFallbackClient?.close();
    _httpFallbackClient = null;
  }

  void _cleanupTimers() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _sizeMonitorTimer?.cancel();
    _sizeMonitorTimer = null;
  }

  Future<void> deleteRecording(Recording recording) async {
    try {
      final file = File(recording.filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[RecordingService] delete file error: $e');
    }

    _recordings.removeWhere((r) => r.id == recording.id);
    await _persistRecordings();
    notifyListeners();
  }

  Future<void> _persistRecordings() async {
    final jsonList = _recordings.map((r) => r.toJson()).toList();
    await storage.saveRecordingsJson(jsonList);
  }

  Future<void> openInExplorer(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path.dirname(filePath)]);
      }
    } catch (e) {
      debugPrint('[RecordingService] openInExplorer error: $e');
    }
  }

  @override
  void dispose() {
    _cleanupTimers();
    _stopHttpFallback();
    super.dispose();
  }
}
