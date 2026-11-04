const express = require('express');
const mongoose = require('mongoose');
const Incidencia = require('../models/Incidencia');
const Categoria = require('../models/Categoria');
const Servicio = require('../models/Servicio');
const notificar = require('../utils/notificar');
const { verificarToken, soloAdmin } = require('../middleware/auth');

const router = express.Router();

const ESTADOS = ['pendiente', 'en_proceso', 'resuelta'];
const PRIORIDADES = ['baja', 'media', 'alta'];
const ETIQUETAS = { pendiente: 'Pendiente', en_proceso: 'En proceso', resuelta: 'Resuelta' };
const PESO_PRIORIDAD = { alta: 3, media: 2, baja: 1 };

// Datos relacionados que se devuelven junto a cada incidencia
const POBLAR = [
  { path: 'categoria', select: 'nombre requiereVisibilidadRestringida' },
  { path: 'usuario', select: 'nombre correo' }
];

// POST /api/incidencias -> cualquier usuario autenticado registra una incidencia
router.post('/', verificarToken, async (req, res) => {
  try {
    const { titulo, descripcion, categoria, ubicacion, prioridad } = req.body;

    if (!titulo || !descripcion || !categoria || !ubicacion) {
      return res.status(400).json({
        mensaje: 'Título, descripción, categoría y ubicación son obligatorios'
      });
    }
    if (!mongoose.isValidObjectId(categoria) || !(await Categoria.exists({ _id: categoria }))) {
      return res.status(400).json({ mensaje: 'La categoría seleccionada no existe' });
    }

    const incidencia = await Incidencia.create({
      titulo,
      descripcion,
      categoria,
      ubicacion,
      prioridad: PRIORIDADES.includes(prioridad) ? prioridad : 'media',
      usuario: req.usuario.id
    });
    await incidencia.populate(POBLAR);

    res.status(201).json(incidencia);
  } catch (error) {
    res.status(400).json({ mensaje: 'Error al registrar la incidencia', error: error.message });
  }
});

// GET /api/incidencias?estado=pendiente
// Admin: ve todas (las más urgentes primero). Usuario general: solo las suyas.
// Así los reportes de categorías de visibilidad restringida (ej. Convivencia)
// solo los ve la administración y quien los reportó.
router.get('/', verificarToken, async (req, res) => {
  try {
    const esAdmin = req.usuario.rol === 'admin';
    const filtro = esAdmin ? {} : { usuario: req.usuario.id };

    if (req.query.estado) {
      if (!ESTADOS.includes(req.query.estado)) {
        return res.status(400).json({ mensaje: 'Estado no válido' });
      }
      filtro.estado = req.query.estado;
    }

    const lista = await Incidencia.find(filtro)
      .populate(POBLAR)
      .sort({ fechaCreacion: -1 })
      .lean();

    if (esAdmin) {
      // Sin resolver primero, luego por prioridad (alta -> baja), luego las más recientes
      const resuelta = (i) => (i.estado === 'resuelta' ? 1 : 0);
      lista.sort((a, b) =>
        resuelta(a) - resuelta(b) ||
        PESO_PRIORIDAD[b.prioridad] - PESO_PRIORIDAD[a.prioridad] ||
        new Date(b.fechaCreacion) - new Date(a.fechaCreacion)
      );
    }

    res.json(lista);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al consultar las incidencias', error: error.message });
  }
});

// GET /api/incidencias/estadisticas/resumen -> solo Admin (panel de control)
router.get('/estadisticas/resumen', verificarToken, soloAdmin, async (req, res) => {
  try {
    const incidencias = await Incidencia.find().populate('categoria', 'nombre').lean();
    const servicios = await Servicio.find().lean();

    const contar = (campo, valores) => {
      const resultado = {};
      valores.forEach((v) => {
        resultado[v] = incidencias.filter((i) => i[campo] === v).length;
      });
      return resultado;
    };
    const horasEntre = (desde, hasta) => (new Date(hasta) - new Date(desde)) / 36e5;
    const promedio = (numeros) =>
      numeros.length ? Math.round((numeros.reduce((a, b) => a + b, 0) / numeros.length) * 10) / 10 : null;

    const porCategoria = {};
    incidencias.forEach((i) => {
      const nombre = i.categoria ? i.categoria.nombre : 'Sin categoría';
      porCategoria[nombre] = (porCategoria[nombre] || 0) + 1;
    });

    res.json({
      total: incidencias.length,
      porEstado: contar('estado', ESTADOS),
      porPrioridad: contar('prioridad', PRIORIDADES),
      porCategoria: Object.entries(porCategoria)
        .map(([nombre, cantidad]) => ({ nombre, cantidad }))
        .sort((a, b) => b.cantidad - a.cantidad),
      tiempoPromedioRespuestaHoras: promedio(
        incidencias.filter((i) => i.fechaRespuesta).map((i) => horasEntre(i.fechaCreacion, i.fechaRespuesta))
      ),
      tiempoPromedioResolucionHoras: promedio(
        incidencias.filter((i) => i.fechaResolucion).map((i) => horasEntre(i.fechaCreacion, i.fechaResolucion))
      ),
      servicios: {
        total: servicios.length,
        pendientes: servicios.filter((s) => s.estado === 'pendiente').length
      }
    });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al calcular las estadísticas', error: error.message });
  }
});

// GET /api/incidencias/:id -> el Admin o quien la reportó
router.get('/:id', verificarToken, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    const incidencia = await Incidencia.findById(req.params.id).populate(POBLAR);
    if (!incidencia) return res.status(404).json({ mensaje: 'Incidencia no encontrada' });

    const esDueno = incidencia.usuario && String(incidencia.usuario._id) === req.usuario.id;
    if (req.usuario.rol !== 'admin' && !esDueno) {
      return res.status(403).json({ mensaje: 'No tienes permiso para ver esta incidencia' });
    }
    res.json(incidencia);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al consultar la incidencia', error: error.message });
  }
});

// PUT /api/incidencias/:id -> solo Admin: cambia estado, prioridad y deja una observación
router.put('/:id', verificarToken, soloAdmin, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    const { estado, prioridad, observacionAdmin } = req.body;

    if (estado !== undefined && !ESTADOS.includes(estado)) {
      return res.status(400).json({ mensaje: 'Estado no válido' });
    }
    if (prioridad !== undefined && !PRIORIDADES.includes(prioridad)) {
      return res.status(400).json({ mensaje: 'Prioridad no válida' });
    }

    const incidencia = await Incidencia.findById(req.params.id);
    if (!incidencia) return res.status(404).json({ mensaje: 'Incidencia no encontrada' });

    const estadoAnterior = incidencia.estado;
    const cambioEstado = estado !== undefined && estado !== estadoAnterior;

    if (cambioEstado) {
      incidencia.estado = estado;
      // Primera vez que se atiende: queda guardado el tiempo de respuesta
      if (estado !== 'pendiente' && !incidencia.fechaRespuesta) {
        incidencia.fechaRespuesta = new Date();
      }
      incidencia.fechaResolucion = estado === 'resuelta' ? new Date() : null;
    }
    if (prioridad !== undefined) incidencia.prioridad = prioridad;
    if (observacionAdmin !== undefined) incidencia.observacionAdmin = String(observacionAdmin).trim();

    await incidencia.save();

    if (cambioEstado) {
      await notificar(
        incidencia.usuario,
        `Tu incidencia "${incidencia.titulo}" cambió de estado a: ${ETIQUETAS[estado]}.`,
        'incidencia',
        incidencia._id
      );
    }

    await incidencia.populate(POBLAR);
    res.json(incidencia);
  } catch (error) {
    res.status(400).json({ mensaje: 'Error al actualizar la incidencia', error: error.message });
  }
});

// DELETE /api/incidencias/:id -> Admin cualquiera; el dueño solo si sigue "pendiente"
router.delete('/:id', verificarToken, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    const incidencia = await Incidencia.findById(req.params.id);
    if (!incidencia) return res.status(404).json({ mensaje: 'Incidencia no encontrada' });

    const esAdmin = req.usuario.rol === 'admin';
    const esDueno = String(incidencia.usuario) === req.usuario.id;
    if (!esAdmin && !(esDueno && incidencia.estado === 'pendiente')) {
      return res.status(403).json({ mensaje: 'Solo puedes cancelar tus reportes que sigan pendientes' });
    }

    await incidencia.deleteOne();
    res.json({ mensaje: 'Incidencia eliminada correctamente' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar la incidencia', error: error.message });
  }
});

module.exports = router;
