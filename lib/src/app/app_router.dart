import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/catalog/presentation/screens/catalogue_screen.dart';
import '../features/catalog/presentation/screens/catalogue_shell.dart';
import '../features/catalog/presentation/screens/home_screen.dart';
import '../features/catalog/presentation/screens/product_detail_screen.dart';
import '../features/enquiry/presentation/screens/enquiry_form_screen.dart';
import '../features/enquiry/presentation/screens/enquiry_success_screen.dart';
import '../features/enquiry/presentation/screens/my_enquiries_screen.dart';
import '../features/hello_world/presentation/screens/hello_world_2_screen.dart';
import '../features/hello_world/presentation/screens/hello_world_screen.dart';
import '../theme/catalogue_theme.dart';

final initialLocationProvider = Provider<String>((ref) => '/');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: ref.watch(initialLocationProvider),
    errorBuilder: (context, state) => Theme(
      data: CatalogueTheme.light(),
      child: Scaffold(
        appBar: AppBar(title: const Text('TribeGreen')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('That page is not part of the catalogue.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => context.go('/'), child: const Text('Back home')),
              ],
            ),
          ),
        ),
      ),
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => CatalogueShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/catalogue', builder: (context, state) => const CatalogueScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/enquire', builder: (context, state) => const EnquiryFormScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/enquiries', builder: (context, state) => const MyEnquiriesScreen())]),
        ],
      ),
      GoRoute(path: '/products/:id', builder: (_, state) => ProductDetailScreen(id: state.pathParameters['id'] ?? '')),
      GoRoute(path: '/enquiry-sent', builder: (context, state) => const EnquirySuccessScreen()),
      GoRoute(path: '/system', builder: (context, state) => const HelloWorldScreen()),
      GoRoute(path: '/hello-world-2', builder: (context, state) => const HelloWorld2Screen()),
    ],
  );
});
