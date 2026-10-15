import '../models/user_model.dart';
import '../models/territory_model.dart';
import '../models/activity_model.dart';

/// Production API Service Contract for CONQUER backend.
/// Real HTTP calls will be implemented here when connecting to the Express API.
abstract class ConquerApiService {
  Future<UserModel> login({required String username, required String password});
  Future<UserModel> getCurrentUser();
  Future<List<TerritoryModel>> getNearbyTerritories();
  Future<List<TerritoryModel>> getMyTerritories(String userId);
  Future<List<ConquestActivityModel>> getActivityHistory(String userId);
  Future<Map<String, dynamic>> submitActivity({
    required String userId,
    required List<MapCoordinate> points,
    required int steps,
    required int durationSeconds,
    required String activityType,
  });
}
