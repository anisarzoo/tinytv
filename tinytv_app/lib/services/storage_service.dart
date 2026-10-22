import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';

class StorageService {
  static const String _keyFavorites = 'tinytv_favorites';
  static const String _keyLastSourceId = 'tinytv_last_source';
  static const String _keyLastChannel = 'tinytv_last_channel';
  static const String _keyCachePrefix = 'tinytv_m3u_cache_';
  static const String _keyVolume = 'tinytv_volume';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Favorites ---
  Set<String> getFavoriteIdentifiers() {
    final list = _prefs.getStringList(_keyFavorites) ?? [];
    return list.toSet();
  }

  Future<void> toggleFavorite(Channel channel) async {
    final favs = getFavoriteIdentifiers();
    final identifier = channel.name.toLowerCase().trim();
    if (favs.contains(identifier)) {
      favs.remove(identifier);
    } else {
      favs.add(identifier);
    }
    await _prefs.setStringList(_keyFavorites, favs.toList());
  }

  bool isFavorite(Channel channel) {
    final favs = getFavoriteIdentifiers();
    return favs.contains(channel.name.toLowerCase().trim());
  }

  // --- Source Selection ---
  String? getLastSourceId() {
    return _prefs.getString(_keyLastSourceId);
  }

  Future<void> saveLastSourceId(String id) async {
    await _prefs.setString(_keyLastSourceId, id);
  }

  // --- Last Played Channel ---
  Channel? getLastPlayedChannel() {
    final jsonStr = _prefs.getString(_keyLastChannel);
    if (jsonStr == null) return null;
    try {
      return Channel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastPlayedChannel(Channel channel) async {
    await _prefs.setString(_keyLastChannel, jsonEncode(channel.toJson()));
  }

  // --- Volume ---
  double getVolume() {
    return _prefs.getDouble(_keyVolume) ?? 100.0;
  }

  Future<void> saveVolume(double volume) async {
    await _prefs.setDouble(_keyVolume, volume);
  }

  // --- Playlist Cache ---
  String? getCachedPlaylist(String sourceId) {
    return _prefs.getString('$_keyCachePrefix$sourceId');
  }

  Future<void> cachePlaylist(String sourceId, String content) async {
    await _prefs.setString('$_keyCachePrefix$sourceId', content);
  }

  // --- Recordings ---
  static const String _keyRecordings = 'tinytv_recordings';

  List<Map<String, dynamic>> getSavedRecordingsJson() {
    final list = _prefs.getStringList(_keyRecordings) ?? [];
    final result = <Map<String, dynamic>>[];
    for (final item in list) {
      try {
        result.add(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {}
    }
    return result;
  }

  Future<void> saveRecordingsJson(List<Map<String, dynamic>> list) async {
    final strings = list.map((item) => jsonEncode(item)).toList();
    await _prefs.setStringList(_keyRecordings, strings);
  }
}
