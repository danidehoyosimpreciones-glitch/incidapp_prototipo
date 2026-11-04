import 'package:flutter/material.dart';
import '../models/notificacion.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';

/// Avisos de cambios de estado en tus incidencias y solicitudes de servicio.
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  late Future<List<Notificacion>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ApiService.obtenerNotificaciones();
  }

  void _cargar() {
    setState(() {
      _futuro = ApiService.obtenerNotificaciones();
    });
  }

  Future<void> _marcarLeida(Notificacion n) async {
    if (n.leida) return;
    await ApiService.marcarNotificacionLeida(n.id);
    if (mounted) _cargar();
  }

  Future<void> _marcarTodas() async {
    final ok = await ApiService.marcarTodasLeidas();
    if (!mounted) return;
    if (ok) {
      _cargar();
    } else {
      mostrarMensaje(context, ApiService.ultimoMensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            tooltip: 'Marcar todas como leídas',
            icon: const Icon(Icons.done_all),
            onPressed: _marcarTodas,
          ),
        ],
      ),
      body: FutureBuilder<List<Notificacion>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return estadoError(snapshot.error.toString(), _cargar);
          }
          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return estadoVacio(
              Icons.notifications_none,
              'No tienes notificaciones',
              'Te avisaremos aquí cuando cambie el estado de tus reportes o solicitudes.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _cargar();
              try {
                await _futuro;
              } catch (_) {}
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = lista[i];
                return ListTile(
                  tileColor: n.leida ? null : Theme.of(context).colorScheme.primaryContainer.withAlpha(90),
                  leading: Icon(
                    n.tipo == 'servicio' ? Icons.volunteer_activism_outlined : Icons.report_problem_outlined,
                    color: n.leida ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    n.mensaje,
                    style: TextStyle(fontWeight: n.leida ? FontWeight.normal : FontWeight.w600),
                  ),
                  subtitle: Text(formatearFecha(n.fecha)),
                  onTap: () => _marcarLeida(n),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
