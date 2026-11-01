import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/catalogue_theme.dart';

class CatalogueShell extends StatelessWidget {
  const CatalogueShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CatalogueTheme.light(),
      child: Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Catalogue'),
            NavigationDestination(icon: Icon(Icons.edit_outlined), selectedIcon: Icon(Icons.edit), label: 'Enquire'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Enquiries'),
          ],
        ),
      ),
    );
  }
}

class CatalogueScaffold extends StatelessWidget {
  const CatalogueScaffold({super.key, required this.body, this.title, this.actions});
  final Widget body;
  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title == null
            ? Image.asset('assets/images/logo/tribegreen-logo.png', height: 28, errorBuilder: (context, error, stack) => const Text('TribeGreen'))
            : Text(title!),
        actions: actions,
        leading: context.canPop() ? BackButton(onPressed: () => context.pop()) : null,
      ),
      body: SafeArea(child: body),
    );
  }
}
