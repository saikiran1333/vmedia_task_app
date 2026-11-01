import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vmedia/src/app/app.dart';
import 'package:vmedia/src/app/app_router.dart';
import 'package:vmedia/src/features/hello_world/domain/entities/hello_entity.dart';
import 'package:vmedia/src/features/hello_world/domain/repositories/hello_repository.dart';
import 'package:vmedia/src/features/hello_world/presentation/viewmodels/hello_viewmodel.dart';

class MockHelloRepository implements HelloRepository {
  @override
  Future<HelloEntity> fetchHelloData() async {
    return const HelloEntity(
      id: 1,
      userId: 1,
      title: 'Mock Title',
      body: 'Mock Body',
    );
  }
}

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/system'),
          helloRepositoryProvider.overrideWithValue(MockHelloRepository()),
        ],
        child: const VmediaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Vmedia'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);
    expect(find.text('Open Hello World 2'), findsOneWidget);
    expect(find.text('Mock Title'), findsOneWidget);
  });

  testWidgets('empty title shows the empty failure and debug path', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/system'),
          helloRepositoryProvider.overrideWithValue(_ThrowingOrEmptyRepository.empty()),
        ],
        child: const VmediaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Error loading data'), findsOneWidget);
    expect(find.text('No data found'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('repository failure shows the error and retry action', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/system'),
          helloRepositoryProvider.overrideWithValue(_ThrowingOrEmptyRepository.failing()),
        ],
        child: const VmediaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Error loading data'), findsOneWidget);
    expect(find.textContaining('network down'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _ThrowingOrEmptyRepository implements HelloRepository {
  _ThrowingOrEmptyRepository.empty() : _fail = false;
  _ThrowingOrEmptyRepository.failing() : _fail = true;

  final bool _fail;

  @override
  Future<HelloEntity> fetchHelloData() async {
    if (_fail) throw Exception('network down');
    return const HelloEntity(id: 2, userId: 2, title: '   ', body: '');
  }
}
