import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/vmedia_theme.dart';
import 'app_router.dart';

class VmediaApp extends ConsumerWidget {
  const VmediaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Vmedia',
      routerConfig: router,
      theme: VmediaTheme.light(),
      darkTheme: VmediaTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
