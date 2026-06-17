import 'package:flutter/material.dart';

import '../core/security/app_lock_gate.dart';
import 'app_router.dart';
import 'app_theme.dart';

class GesundheitApp extends StatelessWidget {
  const GesundheitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLockGate(
      child: MaterialApp.router(
        title: 'Gesundheit Plus',
        theme: AppTheme.light(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
