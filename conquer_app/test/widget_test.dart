import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conquer_app/main.dart';
import 'package:conquer_app/providers/conquest_provider.dart';
import 'package:conquer_app/providers/territory_provider.dart';
import 'package:conquer_app/providers/map_provider.dart';
import 'package:conquer_app/core/constants/map_tile_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CONQUER App UI & Navigation Tests', () {
    testWidgets('Renders Home Map and displays player HUD and map controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ConquerApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Home Map elements are present
      expect(find.text('SHRAVAN'), findsOneWidget);
      expect(find.text('START CONQUEST'), findsOneWidget);
      expect(find.text('MAP'), findsOneWidget);
      expect(find.text('LOGS'), findsOneWidget);
      expect(find.text('EMPIRE'), findsOneWidget);
      expect(find.text('DOSSIER'), findsOneWidget);

      // Verify Map Controls (Zoom in, Zoom out, Layer switcher)
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);

      // Tap zoom in
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap tile provider switcher
      await tester.tap(find.byIcon(Icons.layers_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Navigates through Bottom Navigation tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ConquerApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on LOGS tab
      await tester.tap(find.text('LOGS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ACTIVITY LOGS'), findsOneWidget);
      expect(find.text('TOTAL KM'), findsOneWidget);

      // Tap on EMPIRE tab
      await tester.tap(find.text('EMPIRE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TERRITORY COMMAND'), findsOneWidget);
      expect(find.text('HELD SECTORS'), findsOneWidget);

      // Tap on DOSSIER tab
      await tester.tap(find.text('DOSSIER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('COMMANDER DOSSIER'), findsOneWidget);
      expect(find.text('LIFETIME RECON METRICS'), findsOneWidget);

      // Tap back to MAP tab
      await tester.tap(find.text('MAP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('START CONQUEST'), findsOneWidget);
    });

    testWidgets('Starts active conquest and navigates to ActiveConquestScreen with real map',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ConquerApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap START CONQUEST
      await tester.tap(find.text('START CONQUEST'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Active Conquest Screen
      expect(find.text('CONQUEST ACTIVE'), findsOneWidget);
      expect(find.text('SIM STEP'), findsOneWidget);
      expect(find.text('CLAIM'), findsOneWidget);

      // Tap Close button to return
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('START CONQUEST'), findsOneWidget);
    });
  });

  group('Riverpod State Providers Unit Tests', () {
    test('ConquestNotifier state changes correctly during steps', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(conquestProvider.notifier);
      expect(container.read(conquestProvider).isActive, false);

      notifier.startConquest();
      expect(container.read(conquestProvider).isActive, true);
      expect(container.read(conquestProvider).isPaused, false);

      notifier.togglePause();
      expect(container.read(conquestProvider).isPaused, true);

      notifier.togglePause();
      expect(container.read(conquestProvider).isPaused, false);

      notifier.simulateStep();
      expect(container.read(conquestProvider).steps, greaterThan(65));

      notifier.resetSession();
      expect(container.read(conquestProvider).isActive, false);
    });

    test('TerritoryNotifier reinforces territory and levels up defense', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(territoryProvider.notifier);
      final initialLevel = container
          .read(territoryProvider)
          .territories
          .firstWhere((t) => t.id == 't_alpha')
          .defenseLevel;

      notifier.reinforceTerritory('t_alpha');

      final updatedLevel = container
          .read(territoryProvider)
          .territories
          .firstWhere((t) => t.id == 't_alpha')
          .defenseLevel;

      expect(updatedLevel, initialLevel + 1);
    });

    test('MapNotifier cycles through OpenStreetMap-compatible tile providers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mapProvider.notifier);
      expect(container.read(mapProvider).currentProvider.id, 'carto_dark');

      notifier.toggleNextProvider();
      expect(container.read(mapProvider).currentProvider.id, 'osm_standard');

      notifier.toggleNextProvider();
      expect(container.read(mapProvider).currentProvider.id, 'carto_voyager');

      notifier.setTileProvider(MapTileProviders.cartoDark);
      expect(container.read(mapProvider).currentProvider.id, 'carto_dark');
    });
  });
}
