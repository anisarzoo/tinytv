import 'dart:async';
import 'dart:convert';
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

  // Recording engines
  Process? _ffmpegProcess;
  _DartHlsStreamRecorder? _dartRecorder;

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
    Player? player,
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

      // Start duration ticker (1 second)
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_recordingStartTime != null) {
          _recordingDuration = DateTime.now().difference(_recordingStartTime!);
          notifyListeners();
        }
      });

      // Start file size monitor ticker (1 second)
      _sizeMonitorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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

      // Attempt 1: Try Native FFmpeg Process
      bool ffmpegStarted = false;
      try {
        final ffmpegArgs = [
          '-hide_banner',
          '-loglevel', 'error',
          '-y',
          '-headers', 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36\r\n',
          '-i', channel.url,
          '-c', 'copy',
          '-f', 'mpegts',
          targetPath,
        ];
        _ffmpegProcess = await Process.start('ffmpeg', ffmpegArgs);
        ffmpegStarted = true;

        // Drain stderr to avoid pipe buffers blocking the process
        _ffmpegProcess!.stderr.listen((_) {});
        _ffmpegProcess!.exitCode.then((code) {
          debugPrint('[RecordingService] FFmpeg exited with code: $code');
        });
      } catch (e) {
        debugPrint('[RecordingService] FFmpeg launch failed ($e), falling back to Dart HLS recorder');
        _ffmpegProcess = null;
      }

      // Attempt 2: Fallback to Pure-Dart HLS & Direct Stream Recorder
      if (!ffmpegStarted) {
        _dartRecorder = _DartHlsStreamRecorder(
          url: channel.url,
          targetPath: targetPath,
        );
        await _dartRecorder!.start();
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

  Future<Recording?> stopRecording({Player? player}) async {
    if (!_isRecording) return null;

    final targetPath = _currentRecordingPath;
    final channel = _recordingChannel;
    final startTime = _recordingStartTime ?? DateTime.now();
    final durationSecs = _recordingDuration.inSeconds;

    // 1. Gracefully terminate FFmpeg if active
    if (_ffmpegProcess != null) {
      try {
        _ffmpegProcess!.stdin.writeln('q');
        await _ffmpegProcess!.stdin.flush().catchError((_) {});
        await _ffmpegProcess!.exitCode.timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () {
            _ffmpegProcess?.kill(ProcessSignal.sigterm);
            return 0;
          },
        );
      } catch (e) {
        debugPrint('[RecordingService] Error stopping FFmpeg: $e');
        try {
          _ffmpegProcess?.kill();
        } catch (_) {}
      }
      _ffmpegProcess = null;
    }

    // 2. Stop Dart Recorder if active
    if (_dartRecorder != null) {
      await _dartRecorder!.stop();
      _dartRecorder = null;
    }

    _cleanupTimers();
    _isRecording = false;
    _recordingChannel = null;
    _currentRecordingPath = null;
    _recordingStartTime = null;

    // Allow OS to flush buffers to disk
    await Future.delayed(const Duration(milliseconds: 400));

    Recording? savedRecording;
    if (targetPath != null && channel != null) {
      final f = File(targetPath);
      // Ensure file exists and has actual media data (> 1 KB)
      if (f.existsSync() && f.lengthSync() > 1024) {
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
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }

    notifyListeners();
    return savedRecording;
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
    if (_ffmpegProcess != null) {
      try {
        _ffmpegProcess?.stdin.writeln('q');
        _ffmpegProcess?.kill();
      } catch (_) {}
    }
    _dartRecorder?.stop();
    super.dispose();
  }
}

/// Fallback pure-Dart stream recorder for HLS (.m3u8) and direct HTTP transport streams.
/// Used on mobile/Android/iOS or when FFmpeg is not installed.
class _DartHlsStreamRecorder {
  final String url;
  final String targetPath;
  bool _isCancelled = false;
  http.Client? _client;
  IOSink? _sink;
  Timer? _hlsPollTimer;
  final Set<String> _seenSegments = {};

  _DartHlsStreamRecorder({required this.url, required this.targetPath});

  Future<void> start() async {
    _client = http.Client();
    final file = File(targetPath);
    _sink = file.openWrite(mode: FileMode.writeOnlyAppend);

    try {
      final initialUri = Uri.parse(url);
      final req = http.Request('GET', initialUri)
        ..headers.addAll({
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': '*/*',
        });

      final response = await _client!.send(req);
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';

      if (contentType.contains('mpegurl') || url.contains('.m3u8') || url.contains('.m3u')) {
        final bodyBytes = await response.stream.toBytes();
        final body = utf8.decode(bodyBytes, allowMalformed: true);
        await _handleHls(initialUri, body);
      } else {
        response.stream.listen(
          (chunk) {
            if (!_isCancelled) {
              _sink?.add(chunk);
            }
          },
          onError: (e) {
            debugPrint('[_DartHlsStreamRecorder] direct stream error: $e');
          },
        );
      }
    } catch (e) {
      debugPrint('[_DartHlsStreamRecorder] start error: $e');
    }
  }

  Future<void> _handleHls(Uri playlistUri, String content) async {
    Uri mediaPlaylistUri = playlistUri;
    if (content.contains('#EXT-X-STREAM-INF')) {
      final lines = content.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('#EXT-X-STREAM-INF') && i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
            mediaPlaylistUri = playlistUri.resolve(nextLine);
            break;
          }
        }
      }
    }

    await _pollMediaPlaylist(mediaPlaylistUri);
    _hlsPollTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!_isCancelled) {
        _pollMediaPlaylist(mediaPlaylistUri);
      }
    });
  }

  Future<void> _pollMediaPlaylist(Uri mediaUri) async {
    if (_isCancelled || _client == null) return;
    try {
      final resp = await _client!.get(
        mediaUri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final lines = resp.body.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('#EXTINF') && i + 1 < lines.length) {
            final segLine = lines[i + 1].trim();
            if (segLine.isNotEmpty && !segLine.startsWith('#')) {
              if (!_seenSegments.contains(segLine)) {
                _seenSegments.add(segLine);
                final segUri = mediaUri.resolve(segLine);
                _downloadAndAppendSegment(segUri);
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _downloadAndAppendSegment(Uri segUri) async {
    if (_isCancelled || _client == null) return;
    try {
      final segResp = await _client!.get(
        segUri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 8));

      if (segResp.statusCode == 200 && !_isCancelled) {
        _sink?.add(segResp.bodyBytes);
      }
    } catch (_) {}
  }

  Future<void> stop() async {
    _isCancelled = true;
    _hlsPollTimer?.cancel();
    _hlsPollTimer = null;
    await _sink?.flush().catchError((_) {});
    await _sink?.close().catchError((_) {});
    _sink = null;
    _client?.close();
    _client = null;
  }
}

