import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sports_calendar_sync/presentation/screens/settings_screen.dart';

void main() {
  GoRouter buildRouter(String initialLocation) => GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(
              appBar: AppBar(
                leading: SettingsBackButton(),
                title: Text('設定'),
              ),
            ),
          ),
        ],
      );

  testWidgets('Settings back pops when opened with navigation history', (
    tester,
  ) async {
    final router = buildRouter('/');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.push('/settings');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('Settings back goes Home when direct entry has no history', (
    tester,
  ) async {
    final router = buildRouter('/settings');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(router.canPop(), isFalse);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/');
  });
}
