import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/hello_card_widget.dart';
import '../viewmodels/hello_viewmodel.dart';
import '../viewmodels/state/hello_state.dart';

class HelloWorldScreen extends ConsumerStatefulWidget {
  const HelloWorldScreen({super.key});

  @override
  ConsumerState<HelloWorldScreen> createState() => _HelloWorldScreenState();
}

class _HelloWorldScreenState extends ConsumerState<HelloWorldScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(helloViewModelProvider.notifier).fetchHelloData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final helloState = ref.watch(helloViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vmedia'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hello World',
                style: theme.textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to Vmedia Architecture Demo',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Dummy API Integration UI
              Expanded(
                child: _buildApiSection(helloState, theme),
              ),

              const SizedBox(height: 16),

              // Navigation Button
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/hello-world-2');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Open Hello World 2'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiSection(HelloState state, ThemeData theme) {
    switch (state.status) {
      case HelloStatus.initial:
      case HelloStatus.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );
      case HelloStatus.success:
        if (state.helloData == null) {
          return const Center(child: Text('No data found'));
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dummy API Response:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              HelloCardWidget(entity: state.helloData!),
            ],
          ),
        );
      case HelloStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'Error loading data',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'Unknown error',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  ref.read(helloViewModelProvider.notifier).fetchHelloData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }
  }
}
