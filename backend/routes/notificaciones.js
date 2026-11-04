const express = require('express');
const mongoose = require('mongoose');
const Notificacion = require('../models/Notificacion');
const { verificarToken } = require('../middleware/auth');

const router = express.Router();

// GET /api/notificaciones -> las últimas 50 notificaciones del usuario
router.get('/', verificarToken, async (req, res) => {
  try {
    const lista = await Notificacion.find({ usuario: req.usuario.id })
      .sort({ fecha: -1 })
      .limit(50)
      .lean();
    res.json(lista);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al consultar las notificaciones', error: error.message });
  }
});

// GET /api/notificaciones/contador -> cuántas no ha leído (para el globito de la campana)
router.get('/contador', verificarToken, async (req, res) => {
  try {
    const total = await Notificacion.countDocuments({ usuario: req.usuario.id, leida: false });
    res.json({ total });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al contar las notificaciones', error: error.message });
  }
});

// PUT /api/notificaciones/leer-todas
router.put('/leer-todas', verificarToken, async (req, res) => {
  try {
    await Notificacion.updateMany({ usuario: req.usuario.id, leida: false }, { leida: true });
    res.json({ mensaje: 'Notificaciones marcadas como leídas' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al actualizar las notificaciones', error: error.message });
  }
});

// PUT /api/notificaciones/:id/leida
router.put('/:id/leida', verificarToken, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    const notificacion = await Notificacion.findOneAndUpdate(
      { _id: req.params.id, usuario: req.usuario.id },
      { leida: true },
      { new: true }
    );
    if (!notificacion) return res.status(404).json({ mensaje: 'Notificación no encontrada' });
    res.json(notificacion);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al actualizar la notificación', error: error.message });
  }
});

module.exports = router;
