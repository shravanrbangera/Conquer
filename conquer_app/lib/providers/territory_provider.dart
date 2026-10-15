import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/territory_model.dart';
import '../data/models/territory_event_model.dart';
import '../data/services/backend_territory_service.dart';
import '../data/sources/mock_data.dart';

class TerritoryState {
  final List<TerritoryModel> territories;
  final List<TerritoryEventModel> events;
  final TerritoryModel? selectedTerritory;
  final bool isLoading;
  final String? errorMessage;

  const TerritoryState({
    this.territories = const [],
    this.events = const [],
    this.selectedTerritory,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isEmpty => !isLoading && territories.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;

  TerritoryState copyWith({
    List<TerritoryModel>? territories,
    List<TerritoryEventModel>? events,
    TerritoryModel? selectedTerritory,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TerritoryState(
      territories: territories ?? this.territories,
      events: events ?? this.events,
      selectedTerritory: selectedTerritory ?? this.selectedTerritory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TerritoryNotifier extends Notifier<TerritoryState> {
  late final BackendTerritoryService _service;

  @override
  TerritoryState build() {
    _service = BackendTerritoryService();
    // Microtask to trigger real API fetch on startup
    Future.microtask(() => loadTerritories());
    return TerritoryState(
      territories: List.from(MockData.territories),
      isLoading: false,
    );
  }

  Future<void> loadTerritories() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final territories = await _service.fetchNearbyTerritories();
      final events = await _service.fetchTerritoryEvents();

      if (!ref.mounted) return;
      state = state.copyWith(
        territories: territories,
        events: events,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (!ref.mounted) return;
      // In case of network failure, keep previous territories but note error message
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to sync live territories: $e',
      );
    }
  }

  Future<void> refresh() async {
    await loadTerritories();
  }

  void selectTerritory(TerritoryModel? territory) {
    state = state.copyWith(selectedTerritory: territory);
  }

  void reinforceTerritory(String territoryId) {
    final updated = state.territories.map((t) {
      if (t.id == territoryId) {
        return t.copyWith(
          defenseLevel: t.defenseLevel + 1,
          underAttack: false,
        );
      }
      return t;
    }).toList();

    state = state.copyWith(
      territories: updated,
      selectedTerritory: state.selectedTerritory?.id == territoryId
          ? state.selectedTerritory!.copyWith(
              defenseLevel: state.selectedTerritory!.defenseLevel + 1,
              underAttack: false,
            )
          : state.selectedTerritory,
    );
  }
}

final territoryProvider =
    NotifierProvider<TerritoryNotifier, TerritoryState>(TerritoryNotifier.new);
