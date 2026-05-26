import 'package:flutter/material.dart';

import 'Modules/Iot/machine_dashboard_shell.dart';
import 'Modules/Iot/pages/login_page.dart';
import 'Modules/Iot/services/auth_service.dart';
import 'Modules/Iot/services/customer_access_service.dart';

void main() {
  runApp(const MemcoApp());
}

class MemcoApp extends StatefulWidget {
  const MemcoApp({super.key});

  @override
  State<MemcoApp> createState() => _MemcoAppState();
}

class _MemcoAppState extends State<MemcoApp> {
  AuthSession? _session;
  bool _isRestoringSession = true;

  @override
  void initState() {
    super.initState();
    AuthService.onAuthFailure = _handleAuthExpired;
    _restoreSession();
  }

  @override
  void dispose() {
    if (AuthService.onAuthFailure == _handleAuthExpired) {
      AuthService.onAuthFailure = null;
    }
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final session = await AuthService.restoreSession();

    if (!mounted) return;

    if (session != null) {
      _cacheAccess(session);
    }

    setState(() {
      _session = session;
      _isRestoringSession = false;
    });
  }

  void _cacheAccess(AuthSession session) {
    CustomerAccessService.clearRuntimeAccess();

    if (session.access != null) {
      CustomerAccessService.overwriteAccessForEmail(
        session.user.email,
        session.access!,
      );
    }
  }

  void _handleLogin(AuthSession session) {
    _cacheAccess(session);
    setState(() => _session = session);
  }

  void _handleAuthExpired() {
    CustomerAccessService.clearRuntimeAccess();

    if (!mounted) return;

    setState(() {
      _session = null;
      _isRestoringSession = false;
    });
  }

  void _handleLogout() {
    AuthService.clearSession();
    CustomerAccessService.clearRuntimeAccess();
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MEMCO Industrial IoT',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
        ),
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              decoration: TextDecoration.none,
            ),
            child: child ?? const SizedBox(),
          ),
        );
      },
      home: _isRestoringSession
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _session == null
              ? LoginPage(
                  onLogin: _handleLogin,
                )
              : MachineDashboardShell(
                  user: _session!.user,
                  access: _session!.access,
                  onLogout: _handleLogout,
                ),
    );
  }
}