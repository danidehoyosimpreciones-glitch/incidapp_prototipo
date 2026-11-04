const jwt = require('jsonwebtoken');
const Usuario = require('../models/Usuario');

// Verifica que la petición traiga un token JWT válido.
// Además consulta el rol ACTUAL en la base de datos: así, si un Admin cambia el rol
// de alguien (o elimina su cuenta), el cambio aplica de inmediato sin esperar a que
// el token expire.
async function verificarToken(req, res, next) {
  const header = req.headers['authorization'];
  if (!header) {
    return res.status(401).json({ mensaje: 'No se envió token de acceso' });
  }

  const token = header.startsWith('Bearer ') ? header.split(' ')[1] : header;

  let datos;
  try {
    datos = jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    return res.status(401).json({ mensaje: 'Token inválido o expirado' });
  }

  try {
    const usuario = await Usuario.findById(datos.id).select('rol');
    if (!usuario) {
      return res.status(401).json({ mensaje: 'La cuenta de este usuario ya no existe' });
    }
    req.usuario = { id: String(usuario._id), rol: usuario.rol };
    next();
  } catch (error) {
    return res.status(500).json({ mensaje: 'Error al validar el usuario', error: error.message });
  }
}

// Solo deja pasar si el usuario autenticado tiene rol "admin"
function soloAdmin(req, res, next) {
  if (req.usuario.rol !== 'admin') {
    return res.status(403).json({ mensaje: 'Acceso restringido: se requiere rol de Admin' });
  }
  next();
}

module.exports = { verificarToken, soloAdmin };
