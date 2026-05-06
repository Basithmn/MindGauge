import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static const String _bestTimePrefix = 'best_time_';

  static Future<int?> getBestTime(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_bestTimePrefix$gameId');
  }

  static Future<void> setBestTime(String gameId, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final currentBest = prefs.getInt('$_bestTimePrefix$gameId');
    if (currentBest == null || seconds < currentBest) {
      await prefs.setInt('$_bestTimePrefix$gameId', seconds);
    }
  }
}
