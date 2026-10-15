import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ActivityStorageService {
  ActivityStorageService._();

  static const String _draftFileName = 'active_session_draft.json';
  static const String _queueFileName = 'offline_activities_queue.json';

  // In-memory fallback for web or test environments where disk IO is restricted
  static final Map<String, String> _memoryStore = {};

  static Future<String?> _getStoragePath() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (_) {
      try {
        return Directory.systemTemp.path;
      } catch (_) {
        return null;
      }
    }
  }

  /// Saves currently active tracking session draft to survive interruptions and backgrounding.
  static Future<void> saveSessionDraft(Map<String, dynamic> draftData) async {
    final content = jsonEncode(draftData);
    _memoryStore[_draftFileName] = content;

    final basePath = await _getStoragePath();
    if (basePath != null) {
      try {
        final file = File('$basePath/$_draftFileName');
        await file.writeAsString(content);
      } catch (e) {
        debugPrint('Failed to save session draft to disk: $e');
      }
    }
  }

  /// Restores session draft if one was persisted prior to app interruption.
  static Future<Map<String, dynamic>?> loadSessionDraft() async {
    final basePath = await _getStoragePath();
    if (basePath != null) {
      try {
        final file = File('$basePath/$_draftFileName');
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.isNotEmpty) {
            return jsonDecode(content) as Map<String, dynamic>;
          }
        }
      } catch (e) {
        debugPrint('Failed to load session draft from disk: $e');
      }
    }

    // Memory fallback
    final mem = _memoryStore[_draftFileName];
    if (mem != null && mem.isNotEmpty) {
      return jsonDecode(mem) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clears active session draft upon session completion or discard.
  static Future<void> clearSessionDraft() async {
    _memoryStore.remove(_draftFileName);

    final basePath = await _getStoragePath();
    if (basePath != null) {
      try {
        final file = File('$basePath/$_draftFileName');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to clear session draft from disk: $e');
      }
    }
  }

  /// Enqueues completed activity for later synchronization when network fails.
  static Future<void> enqueueOfflineActivity(Map<String, dynamic> activityData) async {
    List<dynamic> queue = [];
    final basePath = await _getStoragePath();

    // Check memory store or disk
    if (_memoryStore.containsKey(_queueFileName)) {
      queue = jsonDecode(_memoryStore[_queueFileName]!) as List<dynamic>;
    } else if (basePath != null) {
      try {
        final file = File('$basePath/$_queueFileName');
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.isNotEmpty) {
            queue = jsonDecode(content) as List<dynamic>;
          }
        }
      } catch (e) {
        debugPrint('Failed to read offline queue for enqueue: $e');
      }
    }

    queue.add({
      'data': activityData,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    final serialized = jsonEncode(queue);
    _memoryStore[_queueFileName] = serialized;

    if (basePath != null) {
      try {
        final file = File('$basePath/$_queueFileName');
        await file.writeAsString(serialized);
      } catch (e) {
        debugPrint('Failed to write offline queue to disk: $e');
      }
    }
  }

  /// Returns list of queued offline activities awaiting sync.
  static Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    final basePath = await _getStoragePath();
    if (basePath != null) {
      try {
        final file = File('$basePath/$_queueFileName');
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.isNotEmpty) {
            final list = jsonDecode(content) as List<dynamic>;
            return list.cast<Map<String, dynamic>>();
          }
        }
      } catch (e) {
        debugPrint('Failed to read offline queue: $e');
      }
    }

    final mem = _memoryStore[_queueFileName];
    if (mem != null && mem.isNotEmpty) {
      final list = jsonDecode(mem) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Clears queued offline activities after successful submission.
  static Future<void> clearOfflineQueue() async {
    _memoryStore.remove(_queueFileName);

    final basePath = await _getStoragePath();
    if (basePath != null) {
      try {
        final file = File('$basePath/$_queueFileName');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to clear offline queue: $e');
      }
    }
  }
}
