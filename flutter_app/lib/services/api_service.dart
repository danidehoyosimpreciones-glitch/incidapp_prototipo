import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/categoria.dart';
import '../models/incidencia.dart';
import '../models/notificacion.dart';
import '../models/servicio.dart';
import '../models/usuario.dart';
import '../screens/login_screen.dart';
import '../utils/navegacion.dart';

class ApiService {
  // Dirección del backend. Por defecto apunta a tu computador desde el emulador
  // Android (10.0.2.2 es el "localhost" del computador).
  // Para el APK se cambia SIN tocar el código, al compilar:
  //   flutter build apk --release --dart-define=API_URL=https://tu-backend.onrender.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  // Tiempo máximo de espera por petición. Es largo a propósito: un servidor
  // gratuito que estaba dormido puede tardar hasta un minuto en despertar.
  static const Duration _espera = Duration(seconds: 60);

  static const String _sinConexion =
      'No se pudo conectar con el servidor. Revisa tu internet e inténtalo de nuevo en un momento.';

  /// Último mensaje devuelto por el servidor (sirve para mostrar por qué falló algo).
  static String ultimoMensaje = '';

  /// Despierta el servidor si estaba dormido. Se llama al abrir la app, sin esperar
  /// el resultado: mientras la persona escribe su correo, el servidor ya está arrancando.
  /// Cualquier error se ignora a propósito.
  static Future<void> despertarServidor() async {
    try {
      final raiz = baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - 4)
          : baseUrl;
      await http.get(Uri.parse('$raiz/')).timeout(const Duration(seconds: 90));
    } catch (_) {}
  }

  // ---------- Sesión guardada en el dispositivo ----------
  static Future<void> guardarToken(String token, String rol, [String nombre = '']) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('rol', rol);
    if (nombre.isNotEmpty) await prefs.setString('nombre', nombre);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> obtenerRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol');
  }

  static Future<String?> obtenerNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre');
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> _volverAlLogin() async {
    await cerrarSesion();
    navegadorGlobal.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ---------- Petición genérica ----------
  // Devuelve siempre {'exito': bool, 'datos': dynamic, 'mensaje': String}.
  // Nunca lanza errores de red: si no hay conexión o el servidor tarda demasiado,
  // responde con un mensaje claro (así los botones no se quedan cargando para siempre).
  static Future<Map<String, dynamic>> _peticion(
    String metodo,
    String ruta, {
    Map<String, dynamic>? cuerpo,
    bool cerrarSesionEn401 = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$ruta');
      final token = await obtenerToken();
      final cabeceras = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final String? body = cuerpo == null ? null : jsonEncode(cuerpo);

      final Future<http.Response> futuro;
      switch (metodo) {
        case 'POST':
          futuro = http.post(uri, headers: cabeceras, body: body);
          break;
        case 'PUT':
          futuro = http.put(uri, headers: cabeceras, body: body);
          break;
        case 'DELETE':
          futuro = http.delete(uri, headers: cabeceras);
          break;
        default:
          futuro = http.get(uri, headers: cabeceras);
      }
      final res = await futuro.timeout(_espera);

      dynamic datos;
      try {
        datos = res.body.isEmpty ? null : jsonDecode(res.body);
      } catch (_) {
        datos = null;
      }

      final exito = res.statusCode >= 200 && res.statusCode < 300;
      String mensaje = '';
      if (datos is Map && datos['mensaje'] != null) mensaje = datos['mensaje'].toString();
      if (!exito && mensaje.isEmpty) mensaje = 'Error del servidor (${res.statusCode})';

      if (res.statusCode == 401 && cerrarSesionEn401) {
        mensaje = 'Tu sesión expiró. Inicia sesión de nuevo.';
        await _volverAlLogin();
      }

      ultimoMensaje = mensaje;
      return {'exito': exito, 'datos': datos, 'mensaje': mensaje};
    } on TimeoutException {
      ultimoMensaje = _sinConexion;
      return {'exito': false, 'datos': null, 'mensaje': _sinConexion};
    } catch (_) {
      ultimoMensaje = _sinConexion;
      return {'exito': false, 'datos': null, 'mensaje': _sinConexion};
    }
  }

  static List<Map<String, dynamic>> _lista(dynamic datos) {
    if (datos is! List) return [];
    return datos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ---------- Autenticación ----------
  static Future<Map<String, dynamic>> registrar(
      String nombre, String correo, String contrasena) async {
    final r = await _peticion(
      'POST',
      '/auth/register',
      cuerpo: {'nombre': nombre, 'correo': correo, 'contrasena': contrasena},
      cerrarSesionEn401: false,
    );
    if (r['exito'] == true) await _guardarSesionDesdeRespuesta(r['datos']);
    return r;
  }

  static Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final r = await _peticion(
      'POST',
      '/auth/login',
      cuerpo: {'correo': correo, 'contrasena': contrasena},
      cerrarSesionEn401: false,
    );
    if (r['exito'] == true) await _guardarSesionDesdeRespuesta(r['datos']);
    return r;
  }

  static Future<void> _guardarSesionDesdeRespuesta(dynamic datos) async {
    final mapa = Map<String, dynamic>.from(datos as Map);
    final usuario = Map<String, dynamic>.from(mapa['usuario'] as Map);
    await guardarToken(
      mapa['token'].toString(),
      usuario['rol'].toString(),
      (usuario['nombre'] ?? '').toString(),
    );
  }

  /// Trae el perfil actual desde el servidor y actualiza el rol/nombre guardados.
  /// Así, si un Admin te cambió el rol, el menú se ajusta al abrir la app.
  static Future<Usuario?> obtenerPerfil() async {
    final r = await _peticion('GET', '/usuarios/me');
    if (r['exito'] != true) return null;
    final usuario = Usuario.fromJson(Map<String, dynamic>.from(r['datos'] as Map));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rol', usuario.rol);
    await prefs.setString('nombre', usuario.nombre);
    return usuario;
  }

  // ---------- Categorías ----------
  static Future<List<Categoria>> obtenerCategorias() async {
    final r = await _peticion('GET', '/categorias');
    if (r['exito'] != true) throw Exception(r['mensaje']);
    return _lista(r['datos']).map((c) => Categoria.fromJson(c)).toList();
  }

  static Future<bool> crearCategoria(String nombre, String descripcion, bool restringida) async {
    final r = await _peticion('POST', '/categorias', cuerpo: {
      'nombre': nombre,
      'descripcion': descripcion,
      'requiereVisibilidadRestringida': restringida,
    });
    return r['exito'] == true;
  }

  static Future<bool> actualizarCategoria(
      String id, String nombre, String descripcion, bool restringida) async {
    final r = await _peticion('PUT', '/categorias/$id', cuerpo: {
      'nombre': nombre,
      'descripcion': descripcion,
      'requiereVisibilidadRestringida': restringida,
    });
    return r['exito'] == true;
  }

  static Future<bool> eliminarCategoria(String id) async {
    final r = await _peticion('DELETE', '/categorias/$id');
    return r['exito'] == true;
  }

  // ---------- Incidencias ----------
  static Future<List<Incidencia>> obtenerIncidencias({String? estado}) async {
    final ruta = estado == null ? '/incidencias' : '/incidencias?estado=$estado';
    final r = await _peticion('GET', ruta);
    if (r['exito'] != true) throw Exception(r['mensaje']);
    return _lista(r['datos']).map((i) => Incidencia.fromJson(i)).toList();
  }

  static Future<Map<String, dynamic>> crearIncidencia({
    required String titulo,
    required String descripcion,
    required String categoriaId,
    required String ubicacion,
    required String prioridad,
  }) {
    return _peticion('POST', '/incidencias', cuerpo: {
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoriaId,
      'ubicacion': ubicacion,
      'prioridad': prioridad,
    });
  }

  static Future<Map<String, dynamic>> actualizarIncidencia(
    String id, {
    String? estado,
    String? prioridad,
    String? observacion,
  }) {
    final cuerpo = <String, dynamic>{};
    if (estado != null) cuerpo['estado'] = estado;
    if (prioridad != null) cuerpo['prioridad'] = prioridad;
    if (observacion != null) cuerpo['observacionAdmin'] = observacion;
    return _peticion('PUT', '/incidencias/$id', cuerpo: cuerpo);
  }

  static Future<Map<String, dynamic>> eliminarIncidencia(String id) {
    return _peticion('DELETE', '/incidencias/$id');
  }

  static Future<Map<String, dynamic>> obtenerEstadisticas() async {
    final r = await _peticion('GET', '/incidencias/estadisticas/resumen');
    if (r['exito'] != true) throw Exception(r['mensaje']);
    return Map<String, dynamic>.from(r['datos'] as Map);
  }

  // ---------- Servicios comunitarios ----------
  static Future<List<Servicio>> obtenerServicios() async {
    final r = await _peticion('GET', '/servicios');
    if (r['exito'] != true) throw Exception(r['mensaje']);
    return _lista(r['datos']).map((s) => Servicio.fromJson(s)).toList();
  }

  static Future<Map<String, dynamic>> solicitarServicio({
    required String tipoServicio,
    required String descripcion,
    DateTime? fechaProgramada,
  }) {
    return _peticion('POST', '/servicios', cuerpo: {
      'tipoServicio': tipoServicio,
      'descripcion': descripcion,
      if (fechaProgramada != null) 'fechaProgramada': fechaProgramada.toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>> actualizarServicio(
    String id, {
    String? estado,
    String? observacion,
  }) {
    final cuerpo = <String, dynamic>{};
    if (estado != null) cuerpo['estado'] = estado;
    if (observacion != null) cuerpo['observacionAdmin'] = observacion;
    return _peticion('PUT', '/servicios/$id', cuerpo: cuerpo);
  }

  static Future<Map<String, dynamic>> eliminarServicio(String id) {
    return _peticion('DELETE', '/servicios/$id');
  }

  // ---------- Notificaciones ----------
  static Future<List<Notificacion>> obtenerNotificaciones() async {
    final r = await _peticion('GET', '/notificaciones');
    if (r['exito'] != true) throw Exception(r['mensaje']);
    return _lista(r['datos']).map((n) => Notificacion.fromJson(n)).toList();
  }

  static Future<int> contadorNotificaciones() async {
    final r = await _peticion('GET', '/notificaciones/contador');
    if (r['exito'] != true || r['datos'] is! Map) return 0;
    final total = (r['datos'] as Map)['total'];
    return total is num ? total.toInt() : 0;
  }

  static Future<bool> marcarNotificacionLeida(String id) async {
    final r = await _peticion('PUT', '/notificaciones/$id/leida');
    return r['exito'] == true;
  }

  static Future<bool> marcarTodasLeidas() async {
    final r = await _peticion('PUT', '/notificaciones/leer-todas');
    return r['exito'] == true;
  }

  // ---------- Usuarios (solo Admin) ----------
  static Future<List<Usuario>> obtenerUsuarios() async {
    final r = await _peticion('GET', '/usuarios');
    if (r['exito'] != true) throw Exception(r['mensaje']);
    return _lista(r['datos']).map((u) => Usuario.fromJson(u)).toList();
  }

  static Future<Map<String, dynamic>> cambiarRolUsuario(String id, String rol) {
    return _peticion('PUT', '/usuarios/$id', cuerpo: {'rol': rol});
  }

  static Future<Map<String, dynamic>> eliminarUsuario(String id) {
    return _peticion('DELETE', '/usuarios/$id');
  }
}
