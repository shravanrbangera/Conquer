import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/map_tile_providers.dart';

class MapState {
  final MapTileProviderConfig currentProvider;

  const MapState({
    this.currentProvider = MapTileProviders.openStreetMap,
  });

  MapState copyWith({
    MapTileProviderConfig? currentProvider,
  }) {
    return MapState(
      currentProvider: currentProvider ?? this.currentProvider,
    );
  }
}

class MapNotifier extends Notifier<MapState> {
  @override
  MapState build() {
    return const MapState(currentProvider: MapTileProviders.openStreetMap);
  }

  void setTileProvider(MapTileProviderConfig provider) {
    state = state.copyWith(currentProvider: provider);
  }

  void toggleNextProvider() {
    final all = MapTileProviders.all;
    final currentIndex = all.indexWhere((p) => p.id == state.currentProvider.id);
    final nextIndex = (currentIndex + 1) % all.length;
    state = state.copyWith(currentProvider: all[nextIndex]);
  }
}

final mapProvider = NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
