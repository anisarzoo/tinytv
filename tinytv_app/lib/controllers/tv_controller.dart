import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../models/playlist_source.dart';
import '../models/recording.dart';
import '../services/playlist_service.dart';
import '../services/recording_service.dart';
import '../services/storage_service.dart';

class TvController extends ChangeNotifier {
  final StorageService storage;
  late final PlaylistService _playlistService;
  late final RecordingService recordingService;

  late final Player player;
  late final VideoController videoController;

  // Stream subscription handles
  StreamSubscription? _bufferingSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _widthSub;
  StreamSubscription? _heightSub;

  // Sources
  List<PlaylistSource> sources = PlaylistSource.predefinedSources;
  late PlaylistSource currentSource;

  // Channels
  List<Channel> allChannels = [];
  List<Channel> filteredChannels = [];
  Channel? currentChannel;
  Channel? previousChannel;

  // Filter State
  String searchQuery = '';
  String selectedCategory = 'All';
  bool favoritesOnly = false;
  bool hideGeoBlocked = false;
  List<String> categories = ['All'];

  void toggleHideGeoBlocked() {
    hideGeoBlocked = !hideGeoBlocked;
    _applyFilters();
    notifyListeners();
  }

  // Player State
  bool isLoadingChannels = false;
  bool isBuffering = false;
  bool isPlaying = false;
  bool hasError = false;
  String? errorMessage;
  Timer? _playbackTimeoutTimer;
  double volume = 100.0;
  bool isMuted = false;
  double _lastVolumeBeforeMute = 100.0;
  bool isFullScreen = false;
  bool showSidebar = true;

  // Stream Resolution & Technical Info
  int? videoWidth;
  int? videoHeight;
  bool showStreamInfo = false;

  void toggleStreamInfo() {
    showStreamInfo = !showStreamInfo;
    notifyListeners();
  }

  String get streamResolutionLabel {
    if (videoHeight != null) {
      if (videoHeight! >= 2160) return '4K UHD';
      if (videoHeight! >= 1080) return '1080p FHD';
      if (videoHeight! >= 720) return '720p HD';
      if (videoHeight! >= 480) return '480p SD';
      if (videoHeight! > 0) return '${videoHeight}p';
    }
    return 'LIVE';
  }

  // Sleep Timer State
  int? activeSleepTimerMinutes;
  Duration? sleepTimerRemaining;
  Timer? _sleepTimerTicker;

  String get formattedSleepTimerRemaining {
    if (sleepTimerRemaining == null) return '';
    final m = sleepTimerRemaining!.inMinutes;
    final s = sleepTimerRemaining!.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void setSleepTimer(int? minutes) {
    _sleepTimerTicker?.cancel();
    _sleepTimerTicker = null;
    activeSleepTimerMinutes = minutes;

    if (minutes == null || minutes <= 0) {
      sleepTimerRemaining = null;
      notifyListeners();
      return;
    }

    sleepTimerRemaining = Duration(minutes: minutes);
    notifyListeners();

    _sleepTimerTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sleepTimerRemaining != null && sleepTimerRemaining!.inSeconds > 0) {
        sleepTimerRemaining = Duration(seconds: sleepTimerRemaining!.inSeconds - 1);
        notifyListeners();
      } else {
        // Time expired: pause playback
        timer.cancel();
        _sleepTimerTicker = null;
        activeSleepTimerMinutes = null;
        sleepTimerRemaining = null;
        player.pause();
        notifyListeners();
      }
    });
  }

  // Recording & DVR Forwarders
  bool get isRecording => recordingService.isRecording;
  Duration get recordingDuration => recordingService.recordingDuration;
  int get recordingFileSize => recordingService.recordingFileSize;
  List<Recording> get recordings => recordingService.recordings;

  Future<bool> startRecording() async {
    if (currentChannel == null) return false;
    final success = await recordingService.startRecording(
      channel: currentChannel!,
      player: player,
    );
    notifyListeners();
    return success;
  }

  Future<Recording?> stopRecording() async {
    final result = await recordingService.stopRecording(player: player);
    notifyListeners();
    return result;
  }

  Future<void> deleteRecording(Recording rec) async {
    await recordingService.deleteRecording(rec);
    notifyListeners();
  }

  Future<void> openRecordingInExplorer(String filePath) async {
    await recordingService.openInExplorer(filePath);
  }

  Future<void> playRecording(Recording recording) async {
    final recordedChannel = Channel(
      id: recording.id,
      name: '📼 ${recording.channelName}',
      url: recording.filePath,
      category: 'Recordings',
      logo: recording.channelLogo,
    );
    await playChannel(recordedChannel);
  }

  // Quick Channel Recall
  bool get canRecall => previousChannel != null;

  void recallPreviousChannel() {
    if (previousChannel != null) {
      playChannel(previousChannel!);
    }
  }

  void toggleSidebar() {
    showSidebar = !showSidebar;
    notifyListeners();
  }

  // Video Aspect / Scale Mode
  BoxFit videoFit = BoxFit.contain;
  String get videoFitLabel {
    if (videoFit == BoxFit.contain) return 'Fit (16:9)';
    if (videoFit == BoxFit.cover) return 'Zoom (Fill)';
    return 'Stretch';
  }

  void cycleVideoFit() {
    if (videoFit == BoxFit.contain) {
      videoFit = BoxFit.cover;
    } else if (videoFit == BoxFit.cover) {
      videoFit = BoxFit.fill;
    } else {
      videoFit = BoxFit.contain;
    }
    notifyListeners();
  }

  int get favoriteCount => allChannels.where((c) => c.isFavorite).length;

  int get currentChannelNumber {
    if (currentChannel == null || filteredChannels.isEmpty) return 0;
    final idx = filteredChannels.indexWhere((c) => c.url == currentChannel!.url);
    return idx == -1 ? 1 : idx + 1;
  }

  TvController({required this.storage}) {
    _playlistService = PlaylistService(storage);
    recordingService = RecordingService(storage);
    recordingService.addListener(notifyListeners);

    // Initialize media_kit Player & VideoController
    // Lean 2MB buffer for INSTANT playback start (does not delay waiting for huge buffer)
    player = Player(
      configuration: PlayerConfiguration(
        bufferSize: 2 * 1024 * 1024,
      ),
    );
    videoController = VideoController(player);

    // Initial Source
    final lastSourceId = storage.getLastSourceId();
    currentSource = sources.firstWhere(
      (s) => s.id == lastSourceId,
      orElse: () => sources.first,
    );

    // Volume restore
    volume = storage.getVolume();
    player.setVolume(volume);

    // Player listeners
    _bufferingSub = player.stream.buffering.listen((buffering) {
      isBuffering = buffering;
      notifyListeners();
    });

    _playingSub = player.stream.playing.listen((playing) {
      isPlaying = playing;
      if (playing) {
        _playbackTimeoutTimer?.cancel();
        hasError = false;
        errorMessage = null;
        isBuffering = false;
      }
      notifyListeners();
    });

    _errorSub = player.stream.error.listen((error) {
      if (error.isNotEmpty) {
        _playbackTimeoutTimer?.cancel();
        isBuffering = false;
        hasError = true;
        if (currentChannel?.isGeoBlocked == true) {
          errorMessage = 'Geo-Blocked Broadcast: Restricted by the broadcaster to viewers inside their region. Requires a regional VPN.';
        } else {
          errorMessage = error;
        }
        notifyListeners();
      }
    });

    _widthSub = player.stream.width.listen((w) {
      videoWidth = w;
      notifyListeners();
    });

    _heightSub = player.stream.height.listen((h) {
      videoHeight = h;
      notifyListeners();
    });

    // Load initial channels
    loadChannels();
  }

  Future<void> loadChannels({bool forceRefresh = false}) async {
    isLoadingChannels = true;
    hasError = false;
    errorMessage = null;
    notifyListeners();

    try {
      allChannels = await _playlistService.fetchChannels(
        currentSource,
        forceRefresh: forceRefresh,
      );

      // Extract unique categories
      final catSet = <String>{'All'};
      for (final ch in allChannels) {
        if (ch.category != null && ch.category!.trim().isNotEmpty) {
          catSet.add(ch.category!.trim());
        }
      }
      categories = catSet.toList();

      _applyFilters();

      // Auto-play restored or first channel
      if (currentChannel == null && filteredChannels.isNotEmpty) {
        final last = storage.getLastPlayedChannel();
        if (last != null && allChannels.any((c) => c.name == last.name)) {
          final matched = allChannels.firstWhere((c) => c.name == last.name);
          playChannel(matched);
        } else {
          // Play first channel
          playChannel(filteredChannels.first);
        }
      }
    } catch (e) {
      hasError = true;
      errorMessage = 'Failed to load channels: ${e.toString()}';
    } finally {
      isLoadingChannels = false;
      notifyListeners();
    }
  }

  void switchSource(PlaylistSource newSource) {
    if (currentSource.id == newSource.id) return;
    currentSource = newSource;
    storage.saveLastSourceId(newSource.id);
    selectedCategory = 'All';
    searchQuery = '';
    loadChannels();
  }

  Future<void> playChannel(Channel channel) async {
    // If recording active, stop recording cleanly before switching
    if (isRecording) {
      await stopRecording();
    }

    if (currentChannel != null &&
        currentChannel!.url != channel.url &&
        currentChannel!.category != 'Recordings') {
      previousChannel = currentChannel;
    }

    currentChannel = channel;
    hasError = false;
    errorMessage = null;
    isBuffering = true;
    notifyListeners();

    _playbackTimeoutTimer?.cancel();
    _playbackTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (!isPlaying && currentChannel?.url == channel.url) {
        isBuffering = false;
        hasError = true;
        if (channel.isGeoBlocked) {
          errorMessage = 'Geo-Blocked Broadcast: Restricted by broadcaster to viewers inside their region. Requires a regional VPN.';
        } else if (channel.isOffline) {
          errorMessage = 'Channel Offline: This feed is not currently transmitting.';
        } else {
          errorMessage = 'Stream unreachable: Server took too long to respond.';
        }
        notifyListeners();
      }
    });

    if (channel.category != 'Recordings') {
      storage.saveLastPlayedChannel(channel);
    }

    try {
      await player.open(
        Media(
          channel.url,
          httpHeaders: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Accept': '*/*',
          },
        ),
        play: true,
      );
    } catch (e) {
      _playbackTimeoutTimer?.cancel();
      isBuffering = false;
      hasError = true;
      errorMessage = 'Stream playback failed: $e';
      notifyListeners();
    }
  }

  void playNext() {
    if (filteredChannels.isEmpty || currentChannel == null) return;
    final currentIndex = filteredChannels.indexWhere((c) => c.url == currentChannel!.url);
    if (currentIndex != -1 && currentIndex < filteredChannels.length - 1) {
      playChannel(filteredChannels[currentIndex + 1]);
    } else if (filteredChannels.isNotEmpty) {
      playChannel(filteredChannels.first);
    }
  }

  void playPrevious() {
    if (filteredChannels.isEmpty || currentChannel == null) return;
    final currentIndex = filteredChannels.indexWhere((c) => c.url == currentChannel!.url);
    if (currentIndex > 0) {
      playChannel(filteredChannels[currentIndex - 1]);
    } else if (filteredChannels.isNotEmpty) {
      playChannel(filteredChannels.last);
    }
  }

  void togglePlayPause() {
    player.playOrPause();
  }

  void setVolume(double newVol) {
    volume = newVol.clamp(0.0, 100.0);
    isMuted = volume == 0.0;
    player.setVolume(volume);
    storage.saveVolume(volume);
    notifyListeners();
  }

  void toggleMute() {
    if (isMuted) {
      setVolume(_lastVolumeBeforeMute > 0 ? _lastVolumeBeforeMute : 50.0);
    } else {
      _lastVolumeBeforeMute = volume;
      setVolume(0.0);
    }
  }

  Future<void> toggleFavorite(Channel channel) async {
    await storage.toggleFavorite(channel);
    final favSet = storage.getFavoriteIdentifiers();
    for (int i = 0; i < allChannels.length; i++) {
      final ch = allChannels[i];
      if (ch.name.toLowerCase().trim() == channel.name.toLowerCase().trim()) {
        allChannels[i] = ch.copyWith(
          isFavorite: favSet.contains(ch.name.toLowerCase().trim()),
        );
      }
    }
    if (currentChannel?.name.toLowerCase().trim() == channel.name.toLowerCase().trim()) {
      currentChannel = currentChannel?.copyWith(
        isFavorite: favSet.contains(channel.name.toLowerCase().trim()),
      );
    }
    _applyFilters();
    notifyListeners();
  }

  Timer? _searchDebounce;

  void setSearchQuery(String query) {
    searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      _applyFilters();
      notifyListeners();
    });
  }

  void setCategory(String category) {
    selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    favoritesOnly = !favoritesOnly;
    _applyFilters();
    notifyListeners();
  }

  void toggleFullScreen() {
    isFullScreen = !isFullScreen;
    notifyListeners();
  }

  void _applyFilters() {
    final q = searchQuery.toLowerCase().trim();
    filteredChannels = allChannels.where((c) {
      // Hide Geo-blocked or offline channels if toggle enabled
      if (hideGeoBlocked && (c.isGeoBlocked || c.isOffline)) return false;

      // Favorites filter
      if (favoritesOnly && !c.isFavorite) return false;

      // Category filter
      if (selectedCategory != 'All' && c.category != selectedCategory) return false;

      // Search filter
      if (q.isNotEmpty) {
        final matchesName = c.name.toLowerCase().contains(q);
        final matchesCat = c.category?.toLowerCase().contains(q) ?? false;
        if (!matchesName && !matchesCat) return false;
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _playbackTimeoutTimer?.cancel();
    _searchDebounce?.cancel();
    _sleepTimerTicker?.cancel();
    _bufferingSub?.cancel();
    _playingSub?.cancel();
    _errorSub?.cancel();
    _widthSub?.cancel();
    _heightSub?.cancel();
    recordingService.removeListener(notifyListeners);
    recordingService.dispose();
    player.dispose();
    super.dispose();
  }
}
