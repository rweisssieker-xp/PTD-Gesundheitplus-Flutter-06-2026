import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/app_language.dart';
import '../core/localization/app_language_controller.dart';
import '../core/security/app_lock_gate.dart';
import 'app_router.dart';
import 'app_theme.dart';

class GesundheitApp extends ConsumerWidget {
  const GesundheitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language =
        ref.watch(appLanguageControllerProvider).valueOrNull ?? AppLanguage.de;
    return AppLockGate(
      child: MaterialApp.router(
        title: 'Gesundheit Plus',
        locale: Locale(language.code),
        supportedLocales: const [
          Locale('de'),
          Locale('en'),
          Locale('tr'),
          Locale('ar'),
          Locale('uk'),
        ],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
