import '../utils/ui_helpers.dart';

class Servicio {
  final String id;
  final String tipoServicio;
  final String descripcion;
  final String estado;
  final String observacionAdmin;
  final String usuarioNombre;
  final String usuarioCorreo;
  final DateTime fechaSolicitud;
  final DateTime? fechaProgramada;

  Servicio({
    required this.id,
    required this.tipoServicio,
    required this.descripcion,
    required this.estado,
    required this.observacionAdmin,
    required this.usuarioNombre,
    required this.usuarioCorreo,
    required this.fechaSolicitud,
    this.fechaProgramada,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] is Map
        ? Map<String, dynamic>.from(json['usuario'] as Map)
        : <String, dynamic>{};

    return Servicio(
      id: (json['_id'] ?? '').toString(),
      tipoServicio: (json['tipoServicio'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      estado: (json['estado'] ?? 'pendiente').toString(),
      observacionAdmin: (json['observacionAdmin'] ?? '').toString(),
      usuarioNombre: (usuario['nombre'] ?? 'Usuario eliminado').toString(),
      usuarioCorreo: (usuario['correo'] ?? '').toString(),
      fechaSolicitud: parsearFecha(json['fechaSolicitud']) ?? DateTime.now(),
      fechaProgramada: parsearFecha(json['fechaProgramada']),
    );
  }
}
