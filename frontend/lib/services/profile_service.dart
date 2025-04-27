import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class ProfileService extends ChangeNotifier {
  // --- Profile Keys ---
  static const _imagePathKey = 'profileImagePath_v1';
  static const _nameKey = 'profileName_v1';

  // --- Streak Keys ---
  static const _streakCountKey = 'user_streak_count_v1';
  static const _lastCompletionDateKey = 'user_last_completion_date_v1'; // Store as YYYY-MM-DD

  // --- State Variables ---
  String? _imagePath;
  String? _name;
  bool _isLoading = true;
  int _streakCount = 0;
  DateTime? _lastCompletionDate; // Store the actual date object in memory

  // --- Getters ---
  String? get imagePath => _imagePath;
  String get name => _name?.isNotEmpty ?? false ? _name! : 'Demi'; // Default name
  bool get isLoading => _isLoading;
  int get streakCount => _streakCount; // Public getter for streak

  // --- Constructor ---
  ProfileService() {
    _loadProfileData(); // Load profile and streak data on init
  }

  // --- Load Data ---
  Future<void> _loadProfileData() async {
    if (!_isLoading) {
      _isLoading = true;
      // Consider notifyListeners(); if immediate loading feedback is needed
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _imagePath = prefs.getString(_imagePathKey);
      _name = prefs.getString(_nameKey);

      // Load Streak Data
      _streakCount = prefs.getInt(_streakCountKey) ?? 0;
      final dateString = prefs.getString(_lastCompletionDateKey);
      if (dateString != null) {
        _lastCompletionDate = DateTime.tryParse(dateString);
      } else {
        _lastCompletionDate = null;
      }
      debugPrint("[ProfileService] Loaded Streak Count: $_streakCount, Last Completion: $_lastCompletionDate");

    } catch (e) {
      debugPrint("[ProfileService] Error loading profile/streak data: $e");
      _imagePath = null;
      _name = null;
      _streakCount = 0; // Reset on error
      _lastCompletionDate = null;
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify that loading is complete
    }
  }

  // --- Date Helper Functions ---
  DateTime _getTodayDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDate(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  bool _isConsecutiveDay(DateTime? date1, DateTime date2) {
    if (date1 == null) return false;
    final nextDayFromDate1 = date1.add(const Duration(days: 1));
    return _isSameDate(nextDayFromDate1, date2);
  }

  // --- Streak Logic Methods ---

  /// Call this when a task is marked as complete.
  Future<void> updateCompletionStreak() async {
    final today = _getTodayDateOnly();
    DateTime? lastCompletion = _lastCompletionDate; // Use in-memory value
    int currentStreak = _streakCount;       // Use in-memory value
    bool requiresUpdate = false;

    debugPrint("[Streak Update] Start. Today: $today, Last: $lastCompletion, Current: $currentStreak");

    if (lastCompletion == null) {
      debugPrint("[Streak Update] First completion.");
      currentStreak = 1;
      requiresUpdate = true;
    } else {
      if (!_isSameDate(lastCompletion, today)) {
        if (_isConsecutiveDay(lastCompletion, today)) {
          debugPrint("[Streak Update] Consecutive day.");
          currentStreak++;
          requiresUpdate = true;
        } else {
          debugPrint("[Streak Update] Non-consecutive day (gap). Resetting.");
          currentStreak = 1;
          requiresUpdate = true;
        }
      } else {
        debugPrint("[Streak Update] Already completed today. Count remains $currentStreak.");
        // No streak count change, but ensure date is saved by setting requiresUpdate
        requiresUpdate = true;
      }
    }

    if (requiresUpdate) {
       debugPrint("[Streak Update] Saving state. New Count: $currentStreak, New Date: $today");
      // Update in-memory state FIRST for immediate UI feedback
      _streakCount = currentStreak;
      _lastCompletionDate = today;

      try {
        // Save to SharedPreferences asynchronously
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_streakCountKey, _streakCount);
        // Store date as 'YYYY-MM-DD' string for reliable parsing
        await prefs.setString(_lastCompletionDateKey, DateFormat('yyyy-MM-dd').format(today));
      } catch(e) {
         debugPrint("[Streak Update] Error saving streak state: $e");
         // Consider reverting in-memory state or logging error more formally
      } finally {
          notifyListeners(); // Notify UI AFTER in-memory state is updated
      }
    }
  }

  /// Call this on app startup to reset streak if a day was missed.
  Future<void> resetStreakIfNeeded() async {
    // Reload data first to get the most recent persisted state
    await _loadProfileData(); // This loads _lastCompletionDate and _streakCount

    final today = _getTodayDateOnly();
    final lastCompletion = _lastCompletionDate; // Use the freshly loaded value
    int currentStreak = _streakCount; // Use the freshly loaded value

    debugPrint("[Streak Check] Start. Today: $today, Last: $lastCompletion, Current: $currentStreak");

    bool needsReset = false;
    if (lastCompletion != null) {
      final yesterday = today.subtract(const Duration(days: 1));
      // If the last completion was NOT today AND NOT yesterday
      if (!_isSameDate(lastCompletion, today) && !_isSameDate(lastCompletion, yesterday)) {
         debugPrint("[Streak Check] Reset required. Last completion was before yesterday.");
         if(currentStreak > 0) { // Only reset if streak is positive
            needsReset = true;
         } else {
             debugPrint("[Streak Check] Streak already 0. No reset action needed.");
         }
      } else {
           debugPrint("[Streak Check] No reset needed. Last completion was today or yesterday.");
      }
    } else if (currentStreak > 0) {
       // Edge case: No date stored, but streak > 0. Should be reset.
       debugPrint("[Streak Check] No last completion date found, but streak was > 0. Resetting.");
       needsReset = true;
    } else {
         debugPrint("[Streak Check] No last completion date and streak is 0. Nothing to do.");
    }


    if (needsReset) {
        _streakCount = 0; // Update in-memory state
         try {
             final prefs = await SharedPreferences.getInstance();
             await prefs.setInt(_streakCountKey, 0);
             debugPrint("[Streak Check] Streak reset to 0 and saved.");
         } catch(e) {
              debugPrint("[Streak Check] Error saving reset streak state: $e");
              // Could revert _streakCount here if needed
         } finally {
            notifyListeners(); // Notify UI of the change
         }
    }
  }

  // --- Existing Save Methods ---
  Future<void> saveImagePath(String path) async {
    if (_imagePath == path) return;
    String? previousPath = _imagePath;
    _imagePath = path;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_imagePathKey, path);
    } catch (e) {
      debugPrint("[ProfileService] Error saving image path: $e");
      _imagePath = previousPath;
      notifyListeners();
    }
  }

  Future<void> saveName(String newName) async {
    final trimmedName = newName.trim();
    if (_name == trimmedName) return;
    String? previousName = _name;
    _name = trimmedName;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, trimmedName);
    } catch (e) {
       debugPrint("[ProfileService] Error saving name: $e");
       _name = previousName;
       notifyListeners();
    }
  }

  // --- Clear Data Method ---
  Future<void> clearProfileData() async {
    _imagePath = null;
    _name = null;
    _streakCount = 0; // Clear streak state
    _lastCompletionDate = null;
    _isLoading = true; // Optional: indicate loading during clear
    notifyListeners(); // Notify UI immediately

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_imagePathKey);
      await prefs.remove(_nameKey);
      await prefs.remove(_streakCountKey); // Clear streak from storage
      await prefs.remove(_lastCompletionDateKey); // Clear date from storage
      debugPrint("[ProfileService] Cleared profile and streak data.");
    } catch (e) {
       debugPrint("[ProfileService] Error clearing profile data: $e");
    } finally {
       _isLoading = false;
       notifyListeners(); // Notify again after operation
    }
  }
}