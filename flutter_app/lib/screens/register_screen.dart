import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  Future<void> _registrar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final resultado = await ApiService.registrar(
      _nombreCtrl.text.trim(),
      _correoCtrl.text.trim(),
      _contrasenaCtrl.text,
    );

    setState(() => _cargando = false);

    if (resultado['exito']) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _error = resultado['mensaje']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _correoCtrl,
                decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contrasenaCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrarme'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
