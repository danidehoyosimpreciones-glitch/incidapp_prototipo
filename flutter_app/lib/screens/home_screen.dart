import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'categorias_screen.dart';
import 'crear_incidencia_screen.dart';
import 'incidencias_screen.dart';
import 'login_screen.dart';
import 'notificaciones_screen.dart';
import 'panel_admin_screen.dart';
import 'servicios_screen.dart';
import 'usuarios_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _rol = 'general';
  String _nombre = '';
  int _noLeidas = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // Primero lo que está guardado (rápido), luego se confirma con el servidor
    final rol = await ApiService.obtenerRol();
    final nombre = await ApiService.obtenerNombre();
    if (!mounted) return;
    setState(() {
      _rol = rol ?? 'general';
      _nombre = nombre ?? '';
    });

    final perfil = await ApiService.obtenerPerfil();
    if (!mounted || perfil == null) return;
    final noLeidas = await ApiService.contadorNotificaciones();
    if (!mounted) return;
    setState(() {
      _rol = perfil.rol;
      _nombre = perfil.nombre;
      _noLeidas = noLeidas;
    });
  }

  Future<void> _actualizarContador() async {
    final noLeidas = await ApiService.contadorNotificaciones();
    if (!mounted) return;
    setState(() => _noLeidas = noLeidas);
  }

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
    _actualizarContador();
  }

  Future<void> _cerrarSesion() async {
    await ApiService.cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _opcion(IconData icono, String titulo, String subtitulo, Widget pantalla) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icono, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _abrir(pantalla),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = _rol == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('IncidApp'),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            icon: Badge(
              isLabelVisible: _noLeidas > 0,
              label: Text('$_noLeidas'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => _abrir(const NotificacionesScreen()),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _nombre.isEmpty ? 'Bienvenido/a' : 'Hola, $_nombre',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            esAdmin ? 'Sesión de administrador' : 'Sesión de usuario general',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          _opcion(
            Icons.add_alert_outlined,
            'Reportar incidencia',
            'Avisa de un problema en la institución',
            const CrearIncidenciaScreen(),
          ),
          _opcion(
            Icons.list_alt_outlined,
            esAdmin ? 'Todas las incidencias' : 'Mis incidencias',
            esAdmin ? 'Revisa, prioriza y cambia el estado' : 'Consulta cómo van tus reportes',
            IncidenciasScreen(esAdmin: esAdmin),
          ),
          _opcion(
            Icons.volunteer_activism_outlined,
            'Servicios comunitarios',
            esAdmin ? 'Gestiona las solicitudes recibidas' : 'Solicita un servicio y sigue su estado',
            ServiciosScreen(esAdmin: esAdmin),
          ),
          if (esAdmin) ...[
            const SizedBox(height: 8),
            Text('Administración', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _opcion(
              Icons.dashboard_outlined,
              'Panel de control',
              'Estadísticas y tiempos de respuesta',
              const PanelAdminScreen(),
            ),
            _opcion(
              Icons.category_outlined,
              'Categorías de incidencias',
              'Crear, editar y eliminar categorías',
              const CategoriasScreen(),
            ),
            _opcion(
              Icons.people_outline,
              'Usuarios',
              'Cambiar roles y eliminar cuentas',
              const UsuariosScreen(),
            ),
          ],
        ],
      ),
    );
  }
}
