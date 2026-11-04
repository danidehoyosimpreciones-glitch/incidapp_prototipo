import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';

/// Administración de usuarios (solo Admin): cambiar rol y eliminar cuentas.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late Future<List<Usuario>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ApiService.obtenerUsuarios();
  }

  void _cargar() {
    setState(() {
      _futuro = ApiService.obtenerUsuarios();
    });
  }

  Future<bool> _confirmar(String titulo, String detalle, String accion) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(detalle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(accion)),
        ],
      ),
    );
    return respuesta == true;
  }

  Future<void> _cambiarRol(Usuario u) async {
    final nuevoRol = u.esAdmin ? 'general' : 'admin';
    final ok = await _confirmar(
      u.esAdmin ? '¿Quitar rol de Admin?' : '¿Convertir en Admin?',
      u.esAdmin
          ? '${u.nombre} dejará de poder gestionar incidencias, usuarios y categorías.'
          : '${u.nombre} podrá gestionar incidencias, usuarios y categorías.',
      u.esAdmin ? 'Quitar Admin' : 'Convertir en Admin',
    );
    if (!ok || !mounted) return;

    final r = await ApiService.cambiarRolUsuario(u.id, nuevoRol);
    if (!mounted) return;
    if (r['exito'] == true) {
      mostrarMensaje(context, 'Rol actualizado: ${u.nombre} ahora es ${nuevoRol == 'admin' ? 'Admin' : 'usuario general'}');
      _cargar();
    } else {
      mostrarMensaje(context, r['mensaje'].toString());
    }
  }

  Future<void> _eliminar(Usuario u) async {
    final ok = await _confirmar(
      '¿Eliminar a ${u.nombre}?',
      'Se borrará su cuenta junto con todas las incidencias y solicitudes que registró. Esta acción no se puede deshacer.',
      'Eliminar',
    );
    if (!ok || !mounted) return;

    final r = await ApiService.eliminarUsuario(u.id);
    if (!mounted) return;
    if (r['exito'] == true) {
      mostrarMensaje(context, 'Usuario eliminado');
      _cargar();
    } else {
      mostrarMensaje(context, r['mensaje'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: FutureBuilder<List<Usuario>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return estadoError(snapshot.error.toString(), _cargar);
          }
          final usuarios = snapshot.data ?? [];
          if (usuarios.isEmpty) {
            return estadoVacio(Icons.people_outline, 'No hay usuarios', 'Cuando alguien se registre aparecerá aquí.');
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
              itemCount: usuarios.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final u = usuarios[i];
                final inicial = u.nombre.isEmpty ? '?' : u.nombre.substring(0, 1).toUpperCase();
                return ListTile(
                  leading: CircleAvatar(child: Text(inicial)),
                  title: Text(u.nombre),
                  subtitle: Text('${u.correo}\nRegistrado el ${formatearFecha(u.fechaRegistro, conHora: false)}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (u.esAdmin ? Colors.indigo : Colors.grey.shade700).withAlpha(31),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          u.esAdmin ? 'Admin' : 'General',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: u.esAdmin ? Colors.indigo : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (accion) => accion == 'rol' ? _cambiarRol(u) : _eliminar(u),
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'rol',
                            child: Text(u.esAdmin ? 'Quitar rol de Admin' : 'Convertir en Admin'),
                          ),
                          const PopupMenuItem<String>(value: 'eliminar', child: Text('Eliminar usuario')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
