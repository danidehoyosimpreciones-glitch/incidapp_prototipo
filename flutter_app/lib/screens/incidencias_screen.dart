import 'package:flutter/material.dart';
import '../models/incidencia.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';
import 'crear_incidencia_screen.dart';

/// Lista de incidencias con filtro por estado.
/// - Usuario general: ve sus propios reportes y puede cancelar los pendientes.
/// - Admin: ve todas (las más urgentes primero) y puede cambiar estado y prioridad.
class IncidenciasScreen extends StatefulWidget {
  final bool esAdmin;
  const IncidenciasScreen({super.key, required this.esAdmin});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  String? _filtro; // null = todas
  late Future<List<Incidencia>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ApiService.obtenerIncidencias();
  }

  void _cargar() {
    setState(() {
      _futuro = ApiService.obtenerIncidencias(estado: _filtro);
    });
  }

  Future<void> _nueva() async {
    final creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CrearIncidenciaScreen()),
    );
    if (creada == true) _cargar();
  }

  Future<void> _abrirDetalle(Incidencia incidencia) async {
    final huboCambio = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DetalleIncidencia(incidencia: incidencia, esAdmin: widget.esAdmin),
    );
    if (huboCambio == true) _cargar();
  }

  Widget _chipFiltro(String texto, String? valor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: _filtro == valor,
        onSelected: (_) {
          _filtro = valor;
          _cargar();
        },
      ),
    );
  }

  Widget _tarjeta(Incidencia inc) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirDetalle(inc),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      inc.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  chipEstado(inc.estado),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.label_outline, size: 16),
                  const SizedBox(width: 4),
                  Flexible(child: Text(inc.categoriaNombre)),
                  if (inc.categoriaRestringida) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.lock_outline, size: 14, color: Colors.red),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16),
                  const SizedBox(width: 4),
                  Flexible(child: Text(inc.ubicacion)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.flag_outlined, size: 16, color: colorPrioridad(inc.prioridad)),
                  const SizedBox(width: 4),
                  Text(
                    'Prioridad ${etiquetaPrioridad(inc.prioridad).toLowerCase()}',
                    style: TextStyle(color: colorPrioridad(inc.prioridad)),
                  ),
                  const Spacer(),
                  Text(formatearFecha(inc.fechaCreacion),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ),
              if (widget.esAdmin) ...[
                const SizedBox(height: 4),
                Text('Reportó: ${inc.usuarioNombre}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.esAdmin ? 'Todas las incidencias' : 'Mis incidencias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.add),
        label: const Text('Reportar'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _chipFiltro('Todas', null),
                _chipFiltro('Pendientes', 'pendiente'),
                _chipFiltro('En proceso', 'en_proceso'),
                _chipFiltro('Resueltas', 'resuelta'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Incidencia>>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return estadoError(snapshot.error.toString(), _cargar);
                }
                final lista = snapshot.data ?? [];
                return RefreshIndicator(
                  onRefresh: () async {
                    _cargar();
                    try {
                      await _futuro;
                    } catch (_) {}
                  },
                  child: lista.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            estadoVacio(
                              Icons.inbox_outlined,
                              _filtro == null ? 'Aún no hay incidencias' : 'No hay incidencias con este estado',
                              _filtro == null
                                  ? 'Toca "Reportar" para registrar la primera.'
                                  : 'Prueba con otro filtro o desliza hacia abajo para actualizar.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: lista.length,
                          itemBuilder: (context, i) => _tarjeta(lista[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Detalle y seguimiento de una incidencia (hoja inferior).
class _DetalleIncidencia extends StatefulWidget {
  final Incidencia incidencia;
  final bool esAdmin;
  const _DetalleIncidencia({required this.incidencia, required this.esAdmin});

  @override
  State<_DetalleIncidencia> createState() => _DetalleIncidenciaState();
}

class _DetalleIncidenciaState extends State<_DetalleIncidencia> {
  late String _estado;
  late String _prioridad;
  late TextEditingController _observacionCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estado = widget.incidencia.estado;
    _prioridad = widget.incidencia.prioridad;
    _observacionCtrl = TextEditingController(text: widget.incidencia.observacionAdmin);
  }

  @override
  void dispose() {
    _observacionCtrl.dispose();
    super.dispose();
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          Text(valor),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final r = await ApiService.actualizarIncidencia(
      widget.incidencia.id,
      estado: _estado,
      prioridad: _prioridad,
      observacion: _observacionCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _guardando = false);

    final mensajero = ScaffoldMessenger.of(context);
    if (r['exito'] == true) {
      Navigator.of(context).pop(true);
      mensajero.showSnackBar(const SnackBar(content: Text('Cambios guardados. Se notificó a quien reportó.')));
    } else {
      mensajero.showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
    }
  }

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar este reporte?'),
        content: const Text('Se eliminará y la administración dejará de verlo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancelar reporte')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _guardando = true);
    final r = await ApiService.eliminarIncidencia(widget.incidencia.id);
    if (!mounted) return;
    setState(() => _guardando = false);

    final mensajero = ScaffoldMessenger.of(context);
    if (r['exito'] == true) {
      Navigator.of(context).pop(true);
      mensajero.showSnackBar(const SnackBar(content: Text('Reporte cancelado')));
    } else {
      mensajero.showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inc = widget.incidencia;
    final respuesta = inc.fechaRespuesta;
    final resolucion = inc.fechaResolucion;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(inc.titulo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [chipEstado(inc.estado), chipPrioridad(inc.prioridad)]),
            const Divider(height: 24),
            _fila('Categoría',
                inc.categoriaRestringida ? '${inc.categoriaNombre} (confidencial)' : inc.categoriaNombre),
            _fila('Ubicación', inc.ubicacion),
            _fila('Descripción', inc.descripcion),
            if (widget.esAdmin) _fila('Reportado por', '${inc.usuarioNombre} (${inc.usuarioCorreo})'),
            _fila('Registrada el', formatearFecha(inc.fechaCreacion)),
            _fila(
              'Primera respuesta',
              respuesta == null
                  ? 'Aún sin atender'
                  : '${formatearFecha(respuesta)} (a los ${duracionLegible(respuesta.difference(inc.fechaCreacion))})',
            ),
            if (resolucion != null)
              _fila(
                'Resuelta el',
                '${formatearFecha(resolucion)} (a los ${duracionLegible(resolucion.difference(inc.fechaCreacion))})',
              ),
            if (!widget.esAdmin && inc.observacionAdmin.isNotEmpty)
              _fila('Respuesta de la administración', inc.observacionAdmin),
            const SizedBox(height: 8),
            if (widget.esAdmin) ...[
              const Divider(height: 24),
              Text('Gestionar incidencia', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const Text('Estado', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final e in const ['pendiente', 'en_proceso', 'resuelta'])
                    ChoiceChip(
                      label: Text(etiquetaEstado(e)),
                      selected: _estado == e,
                      onSelected: _guardando ? null : (_) => setState(() => _estado = e),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Prioridad', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in const ['baja', 'media', 'alta'])
                    ChoiceChip(
                      label: Text(etiquetaPrioridad(p)),
                      selected: _prioridad == p,
                      onSelected: _guardando ? null : (_) => setState(() => _prioridad = p),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _observacionCtrl,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: decoracion('Respuesta para quien reportó',
                    ayuda: 'Ej: Ya enviamos al técnico, llega mañana'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                ),
              ),
            ] else if (inc.estado == 'pendiente')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _guardando ? null : _cancelar,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar reporte'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
