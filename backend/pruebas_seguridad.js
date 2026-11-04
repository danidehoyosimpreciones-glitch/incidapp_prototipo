// PRUEBAS DE SEGURIDAD Y VALIDACIÓN DEL BACKEND (no necesita conexión a MongoDB)
//
// Levanta el servidor con una base de datos simulada y comprueba que:
//  - sin token o con token inválido nadie entra,
//  - un usuario general no puede hacer acciones de Admin,
//  - los datos incorrectos se rechazan con un mensaje claro,
//  - el Admin no puede eliminarse ni quitarse su propio rol.
//
// Ejecutar con:  npm test
process.env.JWT_SECRET = 'clave_de_prueba';
const express = require('express');
const jwt = require('jsonwebtoken');
const Usuario = require('./models/Usuario');

// Simula la base de datos: 64b0000000000000000000bb es "general", 64b0000000000000000000aa es "admin", 64b0000000000000000000cc ya no existe
const roles = { '64b0000000000000000000bb': 'general', '64b0000000000000000000aa': 'admin' };
Usuario.findById = (id) => ({
  select: async () => (roles[id] ? { _id: id, rol: roles[id] } : null)
});

const app = express();
app.use(express.json());
app.use('/api/incidencias', require('./routes/incidencias'));
app.use('/api/servicios', require('./routes/servicios'));
app.use('/api/usuarios', require('./routes/usuarios'));
app.use('/api/categorias', require('./routes/categorias'));
app.use('/api/notificaciones', require('./routes/notificaciones'));

const token = (id, rolEnToken) => jwt.sign({ id, rol: rolEnToken }, process.env.JWT_SECRET);
let fallos = 0;

async function probar(nombre, metodo, ruta, { usuario, cuerpo, esperado }) {
  const headers = { 'Content-Type': 'application/json' };
  if (usuario) headers.Authorization = 'Bearer ' + usuario;
  const res = await fetch(`http://localhost:${puerto}${ruta}`, {
    method: metodo, headers, body: cuerpo ? JSON.stringify(cuerpo) : undefined
  });
  const ok = res.status === esperado;
  if (!ok) fallos++;
  const json = await res.json().catch(() => ({}));
  console.log(`${ok ? 'PASA ' : 'FALLA'} [${res.status}] ${nombre}${json.mensaje ? '  -> ' + json.mensaje : ''}`);
}

let puerto;
const servidor = app.listen(0, async () => {
  puerto = servidor.address().port;
  const general = token('64b0000000000000000000bb', 'general');
  const adminReal = token('64b0000000000000000000aa', 'admin');
  // Token que DICE ser admin pero en la base de datos es general (rol cambiado después)
  const tokenViejo = token('64b0000000000000000000bb', 'admin');
  const borrado = token('64b0000000000000000000cc', 'general');

  await probar('Sin token no entra', 'GET', '/api/incidencias', { esperado: 401 });
  await probar('Token falso no entra', 'GET', '/api/incidencias', { usuario: 'abc', esperado: 401 });
  await probar('Cuenta eliminada no entra', 'GET', '/api/servicios', { usuario: borrado, esperado: 401 });
  await probar('General NO ve estadísticas', 'GET', '/api/incidencias/estadisticas/resumen', { usuario: general, esperado: 403 });
  await probar('General NO cambia estado de incidencia', 'PUT', '/api/incidencias/64b000000000000000000001', { usuario: general, cuerpo: { estado: 'resuelta' }, esperado: 403 });
  await probar('General NO cambia estado de servicio', 'PUT', '/api/servicios/64b000000000000000000001', { usuario: general, cuerpo: { estado: 'completado' }, esperado: 403 });
  await probar('General NO lista usuarios', 'GET', '/api/usuarios', { usuario: general, esperado: 403 });
  await probar('General NO crea categorías', 'POST', '/api/categorias', { usuario: general, cuerpo: { nombre: 'X' }, esperado: 403 });
  await probar('Token viejo con rol admin pero ya es general: bloqueado', 'GET', '/api/usuarios', { usuario: tokenViejo, esperado: 403 });
  await probar('Incidencia sin datos obligatorios', 'POST', '/api/incidencias', { usuario: general, cuerpo: { titulo: 'x' }, esperado: 400 });
  await probar('Incidencia con categoría inválida', 'POST', '/api/incidencias', { usuario: general, cuerpo: { titulo: 'a', descripcion: 'b', categoria: 'no-es-id', ubicacion: 'c' }, esperado: 400 });
  await probar('Servicio sin tipo', 'POST', '/api/servicios', { usuario: general, cuerpo: {}, esperado: 400 });
  await probar('Servicio con fecha inválida', 'POST', '/api/servicios', { usuario: general, cuerpo: { tipoServicio: 'Limpieza', fechaProgramada: 'ayer' }, esperado: 400 });
  await probar('Estado inválido en filtro', 'GET', '/api/incidencias?estado=inventado', { usuario: general, esperado: 400 });
  await probar('Admin: estado inválido', 'PUT', '/api/incidencias/64b000000000000000000001', { usuario: adminReal, cuerpo: { estado: 'inventado' }, esperado: 400 });
  await probar('Admin: ID inválido no tumba el servidor', 'DELETE', '/api/categorias/abc', { usuario: adminReal, esperado: 400 });
  await probar('Admin no puede eliminarse a sí mismo', 'DELETE', '/api/usuarios/64b0000000000000000000aa', { usuario: adminReal, esperado: 400 });
  await probar('Admin no puede quitarse su rol', 'PUT', '/api/usuarios/64b0000000000000000000aa', { usuario: adminReal, cuerpo: { rol: 'general' }, esperado: 400 });
  await probar('Rol inventado rechazado', 'PUT', '/api/usuarios/64b000000000000000000001', { usuario: adminReal, cuerpo: { rol: 'superman' }, esperado: 400 });

  console.log(fallos === 0 ? '\nTODAS LAS PRUEBAS PASARON' : `\n${fallos} PRUEBA(S) FALLARON`);
  servidor.close();
  process.exit(fallos === 0 ? 0 : 1);
});
