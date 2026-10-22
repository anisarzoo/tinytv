import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinytv_app/models/channel.dart';
import 'package:tinytv_app/models/recording.dart';
import 'package:tinytv_app/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Channel model serialization smoke test', () {
    final channel = Channel(
      id: 'ch_1',
      name: 'BBC News',
      url: 'https://example.com/live.m3u8',
      category: 'News',
    );

    final json = channel.toJson();
    final restored = Channel.fromJson(json);

    expect(restored.name, 'BBC News');
    expect(restored.url, 'https://example.com/live.m3u8');
    expect(restored.category, 'News');
  });

  test('Recording model serialization and formatting test', () {
    final now = DateTime(2026, 10, 23, 14, 30);
    final recording = Recording(
      id: 'rec_123',
      channelName: 'Sky Cinema',
      filePath: r'C:\Videos\TinyTV\SkyCinema.ts',
      recordedAt: now,
      durationSeconds: 125, // 2m 5s
      fileSizeBytes: 15 * 1024 * 1024, // 15 MB
    );

    expect(recording.formattedDuration, '02:05');
    expect(recording.formattedFileSize, '15.0 MB');

    final json = recording.toJson();
    final restored = Recording.fromJson(json);

    expect(restored.id, 'rec_123');
    expect(restored.channelName, 'Sky Cinema');
    expect(restored.durationSeconds, 125);
    expect(restored.fileSizeBytes, 15 * 1024 * 1024);
  });

  test('StorageService persists and retrieves recordings', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    final recording = Recording(
      id: 'rec_test',
      channelName: 'CNN',
      filePath: r'C:\Videos\TinyTV\CNN.ts',
      recordedAt: DateTime.now(),
      durationSeconds: 60,
      fileSizeBytes: 5 * 1024 * 1024,
    );

    await storage.saveRecordingsJson([recording.toJson()]);
    final list = storage.getSavedRecordingsJson();

    expect(list.length, 1);
    expect(list.first['channelName'], 'CNN');
  });
}
