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
    final access = session.access;
    if (access != null) {
      CustomerAccessService.overwriteAccessForEmail(session.user.email, access);
    }
  }

  void _handleLogin(AuthSession session) {
    _cacheAccess(session);

    setState(() {
      _session = session;
    });
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
    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QUIK IoT | MEMCO',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5E4BA8)),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            decoration: TextDecoration.none,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            decoration: TextDecoration.none,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            decoration: TextDecoration.none,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            decoration: TextDecoration.none,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
            decoration: TextDecoration.none,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
            decoration: TextDecoration.none,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            decoration: TextDecoration.none,
          ),
        ),
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: DefaultTextStyle.merge(
            style: const TextStyle(decoration: TextDecoration.none),
            child: child ?? const SizedBox(),
          ),
        );
      },
      home: _isRestoringSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _session == null
          ? LoginPage(onLogin: _handleLogin)
          : MachineDashboardShell(
              user: _session!.user,
              access: _session!.access,
              onLogout: _handleLogout,
            ),
    );
  }
}
