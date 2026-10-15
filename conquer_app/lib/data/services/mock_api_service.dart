import 'api_service.dart';
import '../models/user_model.dart';
import '../models/territory_model.dart';
import '../models/activity_model.dart';
import '../sources/mock_data.dart';

/// Mock API Service for UI and Visual Development.
/// Cleanly separated from production ConquerApiService.
class MockConquerApiService implements ConquerApiService {
  @override
  Future<UserModel> login({required String username, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.currentUser;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return MockData.currentUser;
  }

  @override
  Future<List<TerritoryModel>> getNearbyTerritories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockData.territories;
  }

  @override
  Future<List<TerritoryModel>> getMyTerritories(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockData.territories.where((t) => t.ownerId == userId).toList();
  }

  @override
  Future<List<ConquestActivityModel>> getActivityHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockData.activities;
  }

  @override
  Future<Map<String, dynamic>> submitActivity({
    required String userId,
    required List<MapCoordinate> points,
    required int steps,
    required int durationSeconds,
    required String activityType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'success': true,
      'areaConqueredKm2': 0.78,
      'xpEarned': 180,
      'coinsEarned': 45,
      'trustScore': 98,
      'loopValid': true,
    };
  }
}
