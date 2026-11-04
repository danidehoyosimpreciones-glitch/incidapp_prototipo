import 'package:flutter/material.dart';

// ---------- Textos y colores de estados y prioridades ----------

String etiquetaEstado(String estado) {
  switch (estado) {
    case 'pendiente':
      return 'Pendiente';
    case 'en_proceso':
      return 'En proceso';
    case 'resuelta':
      return 'Resuelta';
    case 'completado':
      return 'Completado';
    case 'rechazado':
      return 'Rechazado';
    default:
      return estado;
  }
}

Color colorEstado(String estado) {
  switch (estado) {
    case 'pendiente':
      return Colors.orange.shade800;
    case 'en_proceso':
      return Colors.blue.shade700;
    case 'resuelta':
    case 'completado':
      return Colors.green.shade700;
    case 'rechazado':
      return Colors.red.shade700;
    default:
      return Colors.grey.shade700;
  }
}

String etiquetaPrioridad(String prioridad) {
  switch (prioridad) {
    case 'baja':
      return 'Baja';
    case 'alta':
      return 'Alta';
    default:
      return 'Media';
  }
}

Color colorPrioridad(String prioridad) {
  switch (prioridad) {
    case 'baja':
      return Colors.green.shade700;
    case 'alta':
      return Colors.red.shade700;
    default:
      return Colors.orange.shade800;
  }
}

// ---------- Fechas ----------

DateTime? parsearFecha(dynamic valor) {
  if (valor == null) return null;
  return DateTime.tryParse(valor.toString())?.toLocal();
}

String formatearFecha(DateTime? fecha, {bool conHora = true}) {
  if (fecha == null) return '—';
  String dos(int n) => n.toString().padLeft(2, '0');
  final dia = '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  return conHora ? '$dia ${dos(fecha.hour)}:${dos(fecha.minute)}' : dia;
}

String duracionLegible(Duration d) {
  if (d.inMinutes < 1) return 'menos de 1 min';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h ${d.inMinutes % 60} min';
  return '${d.inDays} d ${d.inHours % 24} h';
}

// ---------- Widgets reutilizables ----------

Widget _etiqueta(String texto, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha(31),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(120)),
    ),
    child: Text(
      texto,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

Widget chipEstado(String estado) => _etiqueta(etiquetaEstado(estado), colorEstado(estado));

Widget chipPrioridad(String prioridad) =>
    _etiqueta('Prioridad ${etiquetaPrioridad(prioridad).toLowerCase()}', colorPrioridad(prioridad));

InputDecoration decoracion(String etiqueta, {String? ayuda, String? error}) {
  return InputDecoration(
    labelText: etiqueta,
    hintText: ayuda,
    errorText: error,
    border: const OutlineInputBorder(),
  );
}

void mostrarMensaje(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));
}

/// Pantalla/estado vacío: explica qué pasa y qué hacer.
Widget estadoVacio(IconData icono, String titulo, String detalle) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 56, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(detalle, style: TextStyle(color: Colors.grey.shade700), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

/// Estado de error con botón para reintentar.
Widget estadoError(String mensaje, VoidCallback reintentar) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(mensaje.replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: reintentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
