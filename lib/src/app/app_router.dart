import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/hello_world/presentation/screens/hello_world_2_screen.dart';
import '../features/hello_world/presentation/screens/hello_world_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HelloWorldScreen(),
      ),
      GoRoute(
        path: '/hello-world-2',
        builder: (context, state) => const HelloWorld2Screen(),
      ),
    ],
  );
});
