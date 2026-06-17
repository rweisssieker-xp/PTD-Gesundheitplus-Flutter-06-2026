import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared_ui/gp_colors.dart';
import 'security_providers.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  final _pin = TextEditingController();
  bool _checking = true;
  bool _locked = false;
  bool _biometricEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Material(
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator(color: GpColors.emergencyRed),
        ),
      );
    }
    if (!_locked) return widget.child;
    return MaterialApp(
      title: 'Gesundheit Plus',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: GpColors.emergencyRed),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: GpColors.emergencyRed,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gesundheit Plus entsperren',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: '6-stellige PIN',
                        errorText: _error,
                      ),
                      onSubmitted: (_) => _unlockWithPin(),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _unlockWithPin,
                      icon: const Icon(Icons.lock_open_outlined),
                      label: const Text('Entsperren'),
                    ),
                    if (_biometricEnabled) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _unlockWithBiometrics,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Biometrisch entsperren'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    final lock = ref.read(appLockServiceProvider);
    final hasPin = await lock.hasPin().timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );
    final biometricEnabled = hasPin
        ? await lock.isBiometricEnabled().timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          )
        : false;
    if (!mounted) return;
    setState(() {
      _locked = hasPin;
      _biometricEnabled = biometricEnabled;
      _checking = false;
    });
  }

  Future<void> _unlockWithPin() async {
    final success = await ref
        .read(appLockServiceProvider)
        .unlockWithPin(_pin.text);
    if (!mounted) return;
    if (success) {
      setState(() {
        _locked = false;
        _error = null;
      });
    } else {
      setState(() => _error = 'PIN ist nicht korrekt');
    }
  }

  Future<void> _unlockWithBiometrics() async {
    final success = await ref
        .read(appLockServiceProvider)
        .unlockWithBiometrics();
    if (!mounted) return;
    if (success) {
      setState(() => _locked = false);
    } else {
      setState(() => _error = 'Biometrische Entsperrung fehlgeschlagen');
    }
  }
}
