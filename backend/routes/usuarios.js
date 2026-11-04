const express = require('express');
const mongoose = require('mongoose');
const Usuario = require('../models/Usuario');
const Incidencia = require('../models/Incidencia');
const Servicio = require('../models/Servicio');
const Notificacion = require('../models/Notificacion');
const { verificarToken, soloAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/usuarios -> Solo Admin: lista todos los usuarios
router.get('/', verificarToken, soloAdmin, async (req, res) => {
  try {
    const usuarios = await Usuario.find().sort({ fechaRegistro: -1 });
    res.json(usuarios);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al consultar los usuarios', error: error.message });
  }
});

// GET /api/usuarios/me -> Cualquier usuario autenticado: ve su propio perfil
router.get('/me', verificarToken, async (req, res) => {
  try {
    const usuario = await Usuario.findById(req.usuario.id);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    res.json(usuario);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al consultar el perfil', error: error.message });
  }
});

// PUT /api/usuarios/:id -> Solo Admin: actualizar nombre o rol de un usuario
router.put('/:id', verificarToken, soloAdmin, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    const { nombre, rol } = req.body;

    if (rol !== undefined && !['admin', 'general'].includes(rol)) {
      return res.status(400).json({ mensaje: 'Rol no válido' });
    }
    // Evita que el único Admin se quite el rol por accidente y se quede sin acceso
    if (req.params.id === req.usuario.id && rol && rol !== 'admin') {
      return res.status(400).json({ mensaje: 'No puedes quitarte tu propio rol de Admin' });
    }

    const cambios = {};
    if (nombre) cambios.nombre = nombre;
    if (rol) cambios.rol = rol;

    const usuario = await Usuario.findByIdAndUpdate(req.params.id, cambios, {
      new: true,
      runValidators: true
    });
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    res.json(usuario);
  } catch (error) {
    res.status(400).json({ mensaje: 'Error al actualizar usuario', error: error.message });
  }
});

// DELETE /api/usuarios/:id -> Solo Admin: elimina un usuario y todo lo que registró
router.delete('/:id', verificarToken, soloAdmin, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    if (req.params.id === req.usuario.id) {
      return res.status(400).json({ mensaje: 'No puedes eliminar tu propia cuenta' });
    }

    const usuario = await Usuario.findByIdAndDelete(req.params.id);
    if (!usuario) return res.status(404).json({ mensaje: 'Usuario no encontrado' });

    // Para no dejar datos huérfanos
    await Promise.all([
      Incidencia.deleteMany({ usuario: usuario._id }),
      Servicio.deleteMany({ usuario: usuario._id }),
      Notificacion.deleteMany({ usuario: usuario._id })
    ]);

    res.json({ mensaje: 'Usuario eliminado correctamente' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar el usuario', error: error.message });
  }
});

module.exports = router;
