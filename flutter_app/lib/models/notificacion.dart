import '../utils/ui_helpers.dart';

class Notificacion {
  final String id;
  final String mensaje;
  final String tipo;
  final bool leida;
  final DateTime fecha;

  Notificacion({
    required this.id,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.fecha,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: (json['_id'] ?? '').toString(),
      mensaje: (json['mensaje'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      leida: json['leida'] == true,
      fecha: parsearFecha(json['fecha']) ?? DateTime.now(),
    );
  }
}
