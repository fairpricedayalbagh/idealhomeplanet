import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideal_home_planet/app/router.dart';
import 'package:ideal_home_planet/app/theme.dart';
import 'package:ideal_home_planet/core/services/update_service.dart';
import 'package:ideal_home_planet/shared/widgets/update_dialog.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Ideal Home Store',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return _UpdateChecker(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Wrapper widget that checks for updates once the app has a valid context
/// below MaterialApp (so bottom sheets and dialogs work).
class _UpdateChecker extends ConsumerStatefulWidget {
  final Widget child;
  const _UpdateChecker({required this.child});

  @override
  ConsumerState<_UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends ConsumerState<_UpdateChecker> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppVersionInfo?>>(updateCheckProvider, (_, next) {
      if (_dialogShown) return;
      next.whenData((versionInfo) {
        if (versionInfo != null && mounted) {
          _dialogShown = true;
          UpdateDialog.show(context, versionInfo);
        }
      });
    });

    return widget.child;
  }
}
