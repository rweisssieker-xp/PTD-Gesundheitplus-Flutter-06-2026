import 'package:flutter/material.dart';

import 'app_router.dart';
import 'app_theme.dart';

class GesundheitApp extends StatelessWidget {
  const GesundheitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gesundheit Plus',
      theme: AppTheme.light(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
