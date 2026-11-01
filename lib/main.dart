import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app/app.dart';
import 'src/features/enquiry/data/datasources/enquiry_local_datasource.dart';
import 'src/features/enquiry/domain/repositories/enquiry_repository.dart';
import 'src/features/enquiry/presentation/viewmodels/enquiry_viewmodels.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KeyValueStore store;
  try {
    final prefs = await SharedPreferences.getInstance();
    store = SharedPrefsStore(prefs);
  } catch (_) {
    store = UnavailableStore();
  }
  runApp(
    ProviderScope(
      overrides: [storeProvider.overrideWithValue(store)],
      child: const VmediaApp(),
    ),
  );
}
