import '../utils/ui_helpers.dart';

class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final DateTime fechaRegistro;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.fechaRegistro,
  });

  bool get esAdmin => rol == 'admin';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: (json['_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      rol: (json['rol'] ?? 'general').toString(),
      fechaRegistro: parsearFecha(json['fechaRegistro']) ?? DateTime.now(),
    );
  }
}
