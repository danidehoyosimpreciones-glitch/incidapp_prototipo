import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';

class CrearIncidenciaScreen extends StatefulWidget {
  const CrearIncidenciaScreen({super.key});

  @override
  State<CrearIncidenciaScreen> createState() => _CrearIncidenciaScreenState();
}

class _CrearIncidenciaScreenState extends State<CrearIncidenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  late Future<List<Categoria>> _futuroCategorias;
  String? _categoriaId;
  String? _errorCategoria;
  String _prioridad = 'media';
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _futuroCategorias = ApiService.obtenerCategorias();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _ubicacionCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _recargarCategorias() {
    setState(() {
      _futuroCategorias = ApiService.obtenerCategorias();
    });
  }

  Future<void> _enviar() async {
    final camposValidos = _formKey.currentState!.validate();
    if (_categoriaId == null) {
      setState(() => _errorCategoria = 'Selecciona una categoría');
      return;
    }
    if (!camposValidos) return;

    setState(() => _enviando = true);
    final r = await ApiService.crearIncidencia(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      categoriaId: _categoriaId!,
      ubicacion: _ubicacionCtrl.text.trim(),
      prioridad: _prioridad,
    );
    if (!mounted) return;
    setState(() => _enviando = false);

    if (r['exito'] == true) {
      mostrarMensaje(context, 'Incidencia registrada. Puedes seguir su estado en "Mis incidencias".');
      Navigator.of(context).pop(true);
    } else {
      mostrarMensaje(context, r['mensaje'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar incidencia')),
      body: FutureBuilder<List<Categoria>>(
        future: _futuroCategorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return estadoError(snapshot.error.toString(), _recargarCategorias);
          }
          final categorias = snapshot.data ?? [];
          if (categorias.isEmpty) {
            return estadoVacio(
              Icons.category_outlined,
              'Todavía no hay categorías',
              'Pídele a un administrador que cree las categorías de incidencias para poder reportar.',
            );
          }

          final seleccionadas = categorias.where((c) => c.id == _categoriaId).toList();
          final restringida =
              seleccionadas.isNotEmpty && seleccionadas.first.requiereVisibilidadRestringida;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _tituloCtrl,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: decoracion('Título', ayuda: 'Ej: Silla dañada en el salón 204'),
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'Escribe un título de al menos 5 caracteres'
                      : null,
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: decoracion('Categoría', error: _errorCategoria),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _categoriaId,
                      hint: const Text('Selecciona una categoría'),
                      items: categorias
                          .map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.nombre)))
                          .toList(),
                      onChanged: _enviando
                          ? null
                          : (valor) => setState(() {
                                _categoriaId = valor;
                                _errorCategoria = null;
                              }),
                    ),
                  ),
                ),
                if (restringida)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const ListTile(
                        leading: Icon(Icons.lock_outline),
                        title: Text('Reporte confidencial'),
                        subtitle: Text('Solo la administración y tú podrán ver este reporte.'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ubicacionCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: decoracion('Ubicación', ayuda: 'Ej: Bloque B, segundo piso'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Indica dónde ocurrió' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionCtrl,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: decoracion('Descripción', ayuda: 'Cuenta qué pasó y desde cuándo'),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Describe el problema con al menos 10 caracteres'
                      : null,
                ),
                const SizedBox(height: 8),
                const Text('Prioridad', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'baja', label: Text('Baja')),
                    ButtonSegment(value: 'media', label: Text('Media')),
                    ButtonSegment(value: 'alta', label: Text('Alta')),
                  ],
                  selected: {_prioridad},
                  onSelectionChanged:
                      _enviando ? null : (seleccion) => setState(() => _prioridad = seleccion.first),
                ),
                const SizedBox(height: 12),
                Text(
                  'La fecha se registra automáticamente y el estado inicial será "Pendiente".',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_enviando ? 'Enviando...' : 'Registrar incidencia'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
