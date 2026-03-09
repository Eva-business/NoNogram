import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/record_item.dart';

class RecordService {
  static const String finishedPuzzleIdsKey = 'finished_puzzle_ids';
  static const String customRecordsKey = 'custom_records';

  static Future<Set<String>> getFinishedPuzzleIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(finishedPuzzleIdsKey) ?? [];
    return list.toSet();
  }

  static Future<void> markPuzzleFinished(String puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(finishedPuzzleIdsKey) ?? [];

    if (!list.contains(puzzleId)) {
      list.add(puzzleId);
      await prefs.setStringList(finishedPuzzleIdsKey, list);
    }
  }

  static Future<List<RecordItem>> getCustomRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(customRecordsKey) ?? [];

    return list.map((item) => RecordItem.fromJson(jsonDecode(item))).toList();
  }

  static Future<void> addCustomRecord(RecordItem record) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(customRecordsKey) ?? [];

    final exists = list.any((item) {
      final decoded = RecordItem.fromJson(jsonDecode(item));
      return decoded.id == record.id;
    });

    if (exists) return;

    list.add(jsonEncode(record.toJson()));
    await prefs.setStringList(customRecordsKey, list);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(finishedPuzzleIdsKey);
    await prefs.remove(customRecordsKey);
  }
}
