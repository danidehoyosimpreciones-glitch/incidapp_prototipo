import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';

/// Gestión de categorías de incidencias (solo Admin): crear, editar y eliminar.
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late Future<List<Categoria>> _futuroCategorias;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  void _cargarCategorias() {
    setState(() {
      _futuroCategorias = ApiService.obtenerCategorias();
    });
  }

  // Diálogo reutilizado para CREAR y para EDITAR una categoría.
  // Si recibe una categoría existente, se abre con sus datos y actualiza en vez de crear.
  void _mostrarDialogoCategoria({Categoria? categoriaExistente}) {
    final esEdicion = categoriaExistente != null;
    final nombreCtrl = TextEditingController(text: categoriaExistente?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: categoriaExistente?.descripcion ?? '');
    bool restringida = categoriaExistente?.requiereVisibilidadRestringida ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(esEdicion ? 'Editar categoría' : 'Nueva categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: descripcionCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                CheckboxListTile(
                  value: restringida,
                  title: const Text('Visibilidad restringida', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Ej: Convivencia/Bullying', style: TextStyle(fontSize: 11)),
                  onChanged: (v) => setDialogState(() => restringida = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                bool exito;
                if (esEdicion) {
                  exito = await ApiService.actualizarCategoria(
                    categoriaExistente.id,
                    nombreCtrl.text.trim(),
                    descripcionCtrl.text.trim(),
                    restringida,
                  );
                } else {
                  exito = await ApiService.crearCategoria(
                    nombreCtrl.text.trim(),
                    descripcionCtrl.text.trim(),
                    restringida,
                  );
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (exito) {
                  _cargarCategorias();
                } else if (mounted) {
                  mostrarMensaje(context, ApiService.ultimoMensaje);
                }
              },
              child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(Categoria categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar "${categoria.nombre}"?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;

    final exito = await ApiService.eliminarCategoria(categoria.id);
    if (!mounted) return;
    if (exito) {
      _cargarCategorias();
    } else {
      mostrarMensaje(context, ApiService.ultimoMensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías de incidencias')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva categoría',
        onPressed: () => _mostrarDialogoCategoria(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Categoria>>(
        future: _futuroCategorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return estadoError(snapshot.error.toString(), _cargarCategorias);
          }
          final categorias = snapshot.data ?? [];
          if (categorias.isEmpty) {
            return estadoVacio(
              Icons.category_outlined,
              'Aún no hay categorías',
              'Crea la primera con el botón +.',
            );
          }
          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, i) {
              final c = categorias[i];
              return ListTile(
                leading: Icon(
                  c.requiereVisibilidadRestringida ? Icons.lock_outline : Icons.label_outline,
                  color: c.requiereVisibilidadRestringida ? Colors.red : Colors.indigo,
                ),
                title: Text(c.nombre),
                subtitle: Text(c.descripcion.isEmpty ? 'Sin descripción' : c.descripcion),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                      onPressed: () => _mostrarDialogoCategoria(categoriaExistente: c),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => _eliminar(c),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
