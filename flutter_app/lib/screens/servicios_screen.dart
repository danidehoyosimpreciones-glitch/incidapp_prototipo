import 'package:flutter/material.dart';
import '../models/servicio.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';

const List<String> _tiposDeServicio = [
  'Limpieza de áreas comunes',
  'Mantenimiento programado',
  'Apoyo logístico para eventos',
  'Jardinería y poda',
  'Otro',
];

/// Servicios comunitarios.
/// - Usuario general: solicita servicios (con fecha opcional) y sigue su estado.
/// - Admin: ve todas las solicitudes y las aprueba, rechaza o marca como completadas.
class ServiciosScreen extends StatefulWidget {
  final bool esAdmin;
  const ServiciosScreen({super.key, required this.esAdmin});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  late Future<List<Servicio>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ApiService.obtenerServicios();
  }

  void _cargar() {
    setState(() {
      _futuro = ApiService.obtenerServicios();
    });
  }

  Future<void> _solicitar() async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FormularioServicio(),
    );
    if (creado == true) _cargar();
  }

  Future<void> _abrirDetalle(Servicio servicio) async {
    final huboCambio = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DetalleServicio(servicio: servicio, esAdmin: widget.esAdmin),
    );
    if (huboCambio == true) _cargar();
  }

  Widget _tarjeta(Servicio s) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirDetalle(s),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.tipoServicio,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  chipEstado(s.estado),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(s.fechaProgramada == null
                      ? 'Sin fecha programada'
                      : 'Para el ${formatearFecha(s.fechaProgramada, conHora: false)}'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Solicitado el ${formatearFecha(s.fechaSolicitud)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              if (widget.esAdmin) ...[
                const SizedBox(height: 4),
                Text('Solicitó: ${s.usuarioNombre}',
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
      appBar: AppBar(title: const Text('Servicios comunitarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _solicitar,
        icon: const Icon(Icons.add),
        label: const Text('Solicitar'),
      ),
      body: FutureBuilder<List<Servicio>>(
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
                        Icons.volunteer_activism_outlined,
                        'Aún no hay solicitudes',
                        'Toca "Solicitar" para pedir un servicio comunitario.',
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemCount: lista.length,
                    itemBuilder: (context, i) => _tarjeta(lista[i]),
                  ),
          );
        },
      ),
    );
  }
}

/// Formulario para solicitar un servicio (hoja inferior).
class _FormularioServicio extends StatefulWidget {
  const _FormularioServicio();

  @override
  State<_FormularioServicio> createState() => _FormularioServicioState();
}

class _FormularioServicioState extends State<_FormularioServicio> {
  final _descripcionCtrl = TextEditingController();
  String? _tipo;
  DateTime? _fecha;
  String? _errorTipo;
  bool _enviando = false;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy.add(const Duration(days: 1)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Fecha en la que necesitas el servicio',
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _enviar() async {
    if (_tipo == null) {
      setState(() => _errorTipo = 'Selecciona el tipo de servicio');
      return;
    }
    setState(() => _enviando = true);
    final r = await ApiService.solicitarServicio(
      tipoServicio: _tipo!,
      descripcion: _descripcionCtrl.text.trim(),
      fechaProgramada: _fecha,
    );
    if (!mounted) return;
    setState(() => _enviando = false);

    final mensajero = ScaffoldMessenger.of(context);
    if (r['exito'] == true) {
      Navigator.of(context).pop(true);
      mensajero.showSnackBar(const SnackBar(content: Text('Solicitud enviada. Te avisaremos cuando cambie de estado.')));
    } else {
      mensajero.showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Solicitar un servicio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: decoracion('Tipo de servicio', error: _errorTipo),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _tipo,
                  hint: const Text('Selecciona una opción'),
                  items: _tiposDeServicio
                      .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                      .toList(),
                  onChanged: _enviando
                      ? null
                      : (valor) => setState(() {
                            _tipo = valor;
                            _errorTipo = null;
                          }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionCtrl,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: decoracion('Detalles (opcional)', ayuda: 'Ej: Limpieza del patio central'),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _enviando ? null : _elegirFecha,
                    icon: const Icon(Icons.event),
                    label: Text(_fecha == null
                        ? 'Programar fecha (opcional)'
                        : formatearFecha(_fecha, conHora: false)),
                  ),
                ),
                if (_fecha != null)
                  IconButton(
                    tooltip: 'Quitar fecha',
                    icon: const Icon(Icons.close),
                    onPressed: _enviando ? null : () => setState(() => _fecha = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _enviando ? null : _enviar,
                icon: _enviando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_enviando ? 'Enviando...' : 'Enviar solicitud'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detalle y seguimiento de un servicio (hoja inferior).
class _DetalleServicio extends StatefulWidget {
  final Servicio servicio;
  final bool esAdmin;
  const _DetalleServicio({required this.servicio, required this.esAdmin});

  @override
  State<_DetalleServicio> createState() => _DetalleServicioState();
}

class _DetalleServicioState extends State<_DetalleServicio> {
  late String _estado;
  late TextEditingController _observacionCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estado = widget.servicio.estado;
    _observacionCtrl = TextEditingController(text: widget.servicio.observacionAdmin);
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
    final r = await ApiService.actualizarServicio(
      widget.servicio.id,
      estado: _estado,
      observacion: _observacionCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _guardando = false);

    final mensajero = ScaffoldMessenger.of(context);
    if (r['exito'] == true) {
      Navigator.of(context).pop(true);
      mensajero.showSnackBar(const SnackBar(content: Text('Cambios guardados. Se notificó al solicitante.')));
    } else {
      mensajero.showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
    }
  }

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar esta solicitud?'),
        content: const Text('Se eliminará y la administración dejará de verla.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancelar solicitud')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _guardando = true);
    final r = await ApiService.eliminarServicio(widget.servicio.id);
    if (!mounted) return;
    setState(() => _guardando = false);

    final mensajero = ScaffoldMessenger.of(context);
    if (r['exito'] == true) {
      Navigator.of(context).pop(true);
      mensajero.showSnackBar(const SnackBar(content: Text('Solicitud cancelada')));
    } else {
      mensajero.showSnackBar(SnackBar(content: Text(r['mensaje'].toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.servicio;

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
            Text(s.tipoServicio, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            chipEstado(s.estado),
            const Divider(height: 24),
            if (s.descripcion.isNotEmpty) _fila('Detalles', s.descripcion),
            _fila('Fecha programada',
                s.fechaProgramada == null ? 'Sin fecha' : formatearFecha(s.fechaProgramada, conHora: false)),
            _fila('Solicitado el', formatearFecha(s.fechaSolicitud)),
            if (widget.esAdmin) _fila('Solicitado por', '${s.usuarioNombre} (${s.usuarioCorreo})'),
            if (!widget.esAdmin && s.observacionAdmin.isNotEmpty)
              _fila('Respuesta de la administración', s.observacionAdmin),
            const SizedBox(height: 8),
            if (widget.esAdmin) ...[
              const Divider(height: 24),
              Text('Gestionar solicitud', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final e in const ['pendiente', 'en_proceso', 'completado', 'rechazado'])
                    ChoiceChip(
                      label: Text(etiquetaEstado(e)),
                      selected: _estado == e,
                      onSelected: _guardando ? null : (_) => setState(() => _estado = e),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _observacionCtrl,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: decoracion('Respuesta para el solicitante',
                    ayuda: 'Ej: Aprobado, pasaremos el jueves a las 8 a. m.'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                ),
              ),
            ] else if (s.estado == 'pendiente')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _guardando ? null : _cancelar,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar solicitud'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
