import '../utils/ui_helpers.dart';

class Incidencia {
  final String id;
  final String titulo;
  final String descripcion;
  final String ubicacion;
  final String estado;
  final String prioridad;
  final String observacionAdmin;
  final String categoriaNombre;
  final bool categoriaRestringida;
  final String usuarioNombre;
  final String usuarioCorreo;
  final DateTime fechaCreacion;
  final DateTime? fechaRespuesta;
  final DateTime? fechaResolucion;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.ubicacion,
    required this.estado,
    required this.prioridad,
    required this.observacionAdmin,
    required this.categoriaNombre,
    required this.categoriaRestringida,
    required this.usuarioNombre,
    required this.usuarioCorreo,
    required this.fechaCreacion,
    this.fechaRespuesta,
    this.fechaResolucion,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    final categoria = json['categoria'] is Map
        ? Map<String, dynamic>.from(json['categoria'] as Map)
        : <String, dynamic>{};
    final usuario = json['usuario'] is Map
        ? Map<String, dynamic>.from(json['usuario'] as Map)
        : <String, dynamic>{};

    return Incidencia(
      id: (json['_id'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      ubicacion: (json['ubicacion'] ?? '').toString(),
      estado: (json['estado'] ?? 'pendiente').toString(),
      prioridad: (json['prioridad'] ?? 'media').toString(),
      observacionAdmin: (json['observacionAdmin'] ?? '').toString(),
      categoriaNombre: (categoria['nombre'] ?? 'Sin categoría').toString(),
      categoriaRestringida: categoria['requiereVisibilidadRestringida'] == true,
      usuarioNombre: (usuario['nombre'] ?? 'Usuario eliminado').toString(),
      usuarioCorreo: (usuario['correo'] ?? '').toString(),
      fechaCreacion: parsearFecha(json['fechaCreacion']) ?? DateTime.now(),
      fechaRespuesta: parsearFecha(json['fechaRespuesta']),
      fechaResolucion: parsearFecha(json['fechaResolucion']),
    );
  }
}
