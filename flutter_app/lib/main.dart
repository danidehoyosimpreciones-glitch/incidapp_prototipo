import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'utils/navegacion.dart';

void main() {
  // Despierta el servidor en segundo plano mientras la persona escribe sus datos.
  unawaited(ApiService.despertarServidor());
  runApp(const IncidApp());
}

class IncidApp extends StatelessWidget {
  const IncidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IncidApp',
      debugShowCheckedModeBanner: false,
      navigatorKey: navegadorGlobal,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const _PantallaInicial(),
    );
  }
}

/// Si ya hay una sesión guardada entra directo al menú; si no, muestra el Login.
class _PantallaInicial extends StatelessWidget {
  const _PantallaInicial();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiService.obtenerToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data != null ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
