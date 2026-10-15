import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/activity_model.dart';
import '../data/sources/mock_data.dart';

enum ActivityFilter { all, running, walking }

class ActivityState {
  final List<ConquestActivityModel> activities;
  final ActivityFilter filter;

  const ActivityState({
    required this.activities,
    this.filter = ActivityFilter.all,
  });

  List<ConquestActivityModel> get filteredActivities {
    switch (filter) {
      case ActivityFilter.all:
        return activities;
      case ActivityFilter.running:
        return activities.where((a) => a.type == 'running').toList();
      case ActivityFilter.walking:
        return activities.where((a) => a.type == 'walking').toList();
    }
  }

  double get totalDistanceKm =>
      activities.fold(0.0, (sum, a) => sum + a.distanceKm);

  int get totalSteps => activities.fold(0, (sum, a) => sum + a.steps);

  double get totalAreaConquered =>
      activities.fold(0.0, (sum, a) => sum + a.areaConqueredKm2);

  ActivityState copyWith({
    List<ConquestActivityModel>? activities,
    ActivityFilter? filter,
  }) {
    return ActivityState(
      activities: activities ?? this.activities,
      filter: filter ?? this.filter,
    );
  }
}

class ActivityNotifier extends Notifier<ActivityState> {
  @override
  ActivityState build() {
    return ActivityState(activities: List.from(MockData.activities));
  }

  void setFilter(ActivityFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void addActivity(ConquestActivityModel activity) {
    state = state.copyWith(
      activities: [activity, ...state.activities],
    );
  }
}

final activityProvider =
    NotifierProvider<ActivityNotifier, ActivityState>(ActivityNotifier.new);
