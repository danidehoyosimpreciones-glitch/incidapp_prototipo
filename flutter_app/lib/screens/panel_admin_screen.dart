import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';

/// Panel de control del Admin: estadísticas básicas y control de tiempos de respuesta.
class PanelAdminScreen extends StatefulWidget {
  const PanelAdminScreen({super.key});

  @override
  State<PanelAdminScreen> createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends State<PanelAdminScreen> {
  late Future<Map<String, dynamic>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ApiService.obtenerEstadisticas();
  }

  void _cargar() {
    setState(() {
      _futuro = ApiService.obtenerEstadisticas();
    });
  }

  int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;

  String _horas(dynamic valor) {
    if (valor is! num) return 'Sin datos aún';
    if (valor < 1) return '${(valor * 60).round()} min';
    return '${valor.toStringAsFixed(1)} h';
  }

  Widget _numeroGrande(String titulo, int valor, IconData icono, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color),
              const SizedBox(height: 8),
              Text('$valor', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: color)),
              Text(titulo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tiempo(String titulo, String valor, IconData icono) {
    return Card(
      child: ListTile(
        leading: Icon(icono),
        title: Text(titulo),
        trailing: Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de control')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return estadoError(snapshot.error.toString(), _cargar);
          }
          final d = snapshot.data!;
          final total = _numero(d['total']);
          final porEstado = Map<String, dynamic>.from((d['porEstado'] ?? {}) as Map);
          final porPrioridad = Map<String, dynamic>.from((d['porPrioridad'] ?? {}) as Map);
          final servicios = Map<String, dynamic>.from((d['servicios'] ?? {}) as Map);
          final categorias = (d['porCategoria'] is List) ? d['porCategoria'] as List : [];

          return RefreshIndicator(
            onRefresh: () async {
              _cargar();
              try {
                await _futuro;
              } catch (_) {}
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                Row(children: [
                  _numeroGrande('Incidencias', total, Icons.report_problem_outlined, Colors.indigo),
                  _numeroGrande('Pendientes', _numero(porEstado['pendiente']), Icons.hourglass_empty,
                      colorEstado('pendiente')),
                ]),
                Row(children: [
                  _numeroGrande('En proceso', _numero(porEstado['en_proceso']), Icons.build_outlined,
                      colorEstado('en_proceso')),
                  _numeroGrande('Resueltas', _numero(porEstado['resuelta']), Icons.check_circle_outline,
                      colorEstado('resuelta')),
                ]),
                const SizedBox(height: 8),
                _tiempo('Tiempo promedio de primera respuesta', _horas(d['tiempoPromedioRespuestaHoras']),
                    Icons.timer_outlined),
                _tiempo('Tiempo promedio de resolución', _horas(d['tiempoPromedioResolucionHoras']),
                    Icons.task_alt),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Por prioridad', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final p in const ['alta', 'media', 'baja'])
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Text('${_numero(porPrioridad[p])}',
                                    style: TextStyle(
                                        fontSize: 22, fontWeight: FontWeight.bold, color: colorPrioridad(p))),
                                Text(etiquetaPrioridad(p)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Por categoría', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                if (categorias.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Todavía no hay incidencias registradas.',
                        style: TextStyle(color: Colors.grey.shade700)),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (final c in categorias)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text((c as Map)['nombre'].toString(),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: total == 0 ? 0 : _numero(c['cantidad']) / total,
                                      minHeight: 10,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('${_numero(c['cantidad'])}',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.volunteer_activism_outlined),
                    title: const Text('Solicitudes de servicios'),
                    subtitle: Text('${_numero(servicios['pendientes'])} pendientes de atender'),
                    trailing: Text('${_numero(servicios['total'])}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
