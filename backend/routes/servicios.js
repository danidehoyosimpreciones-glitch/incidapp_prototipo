const express = require('express');
const mongoose = require('mongoose');
const Servicio = require('../models/Servicio');
const notificar = require('../utils/notificar');
const { verificarToken, soloAdmin } = require('../middleware/auth');

const router = express.Router();

const ESTADOS = ['pendiente', 'en_proceso', 'completado', 'rechazado'];
const ETIQUETAS = {
  pendiente: 'Pendiente',
  en_proceso: 'En proceso',
  completado: 'Completado',
  rechazado: 'Rechazado'
};

const POBLAR = [{ path: 'usuario', select: 'nombre correo' }];

// POST /api/servicios -> cualquier usuario autenticado solicita un servicio
router.post('/', verificarToken, async (req, res) => {
  try {
    const { tipoServicio, descripcion, fechaProgramada } = req.body;

    if (!tipoServicio) {
      return res.status(400).json({ mensaje: 'El tipo de servicio es obligatorio' });
    }

    let fecha = null;
    if (fechaProgramada) {
      fecha = new Date(fechaProgramada);
      if (isNaN(fecha.getTime())) {
        return res.status(400).json({ mensaje: 'La fecha programada no es válida' });
      }
    }

    const servicio = await Servicio.create({
      tipoServicio,
      descripcion: descripcion || '',
      fechaProgramada: fecha,
      usuario: req.usuario.id
    });
    await servicio.populate(POBLAR);

    res.status(201).json(servicio);
  } catch (error) {
    res.status(400).json({ mensaje: 'Error al solicitar el servicio', error: error.message });
  }
});

// GET /api/servicios?estado=pendiente -> Admin ve todas; usuario general solo las suyas
router.get('/', verificarToken, async (req, res) => {
  try {
    const filtro = req.usuario.rol === 'admin' ? {} : { usuario: req.usuario.id };
    if (req.query.estado) {
      if (!ESTADOS.includes(req.query.estado)) {
        return res.status(400).json({ mensaje: 'Estado no válido' });
      }
      filtro.estado = req.query.estado;
    }
    const lista = await Servicio.find(filtro).populate(POBLAR).sort({ fechaSolicitud: -1 }).lean();
    res.json(lista);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al consultar los servicios', error: error.message });
  }
});

// PUT /api/servicios/:id -> solo Admin: cambia el estado y deja una observación
router.put('/:id', verificarToken, soloAdmin, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    const { estado, observacionAdmin } = req.body;
    if (estado !== undefined && !ESTADOS.includes(estado)) {
      return res.status(400).json({ mensaje: 'Estado no válido' });
    }

    const servicio = await Servicio.findById(req.params.id);
    if (!servicio) return res.status(404).json({ mensaje: 'Servicio no encontrado' });

    const cambioEstado = estado !== undefined && estado !== servicio.estado;
    if (cambioEstado) servicio.estado = estado;
    if (observacionAdmin !== undefined) servicio.observacionAdmin = String(observacionAdmin).trim();

    await servicio.save();

    if (cambioEstado) {
      await notificar(
        servicio.usuario,
        `Tu solicitud de "${servicio.tipoServicio}" cambió de estado a: ${ETIQUETAS[estado]}.`,
        'servicio',
        servicio._id
      );
    }

    await servicio.populate(POBLAR);
    res.json(servicio);
  } catch (error) {
    res.status(400).json({ mensaje: 'Error al actualizar el servicio', error: error.message });
  }
});

// DELETE /api/servicios/:id -> Admin cualquiera; el dueño solo si sigue "pendiente"
router.delete('/:id', verificarToken, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    const servicio = await Servicio.findById(req.params.id);
    if (!servicio) return res.status(404).json({ mensaje: 'Servicio no encontrado' });

    const esAdmin = req.usuario.rol === 'admin';
    const esDueno = String(servicio.usuario) === req.usuario.id;
    if (!esAdmin && !(esDueno && servicio.estado === 'pendiente')) {
      return res.status(403).json({ mensaje: 'Solo puedes cancelar tus solicitudes que sigan pendientes' });
    }

    await servicio.deleteOne();
    res.json({ mensaje: 'Solicitud eliminada correctamente' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar la solicitud', error: error.message });
  }
});

module.exports = router;
