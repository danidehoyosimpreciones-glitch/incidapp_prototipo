const express = require('express');
const mongoose = require('mongoose');
const Categoria = require('../models/Categoria');
const Incidencia = require('../models/Incidencia');
const { verificarToken, soloAdmin } = require('../middleware/auth');

const router = express.Router();

// Traduce el error de nombre duplicado de MongoDB a un mensaje entendible
function mensajeError(error, porDefecto) {
  if (error.code === 11000) return 'Ya existe una categoría con ese nombre';
  return porDefecto;
}

// GET /api/categorias -> Cualquier usuario autenticado puede ver las categorías
router.get('/', verificarToken, async (req, res) => {
  try {
    const categorias = await Categoria.find().sort({ nombre: 1 });
    res.json(categorias);
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al consultar las categorías', error: error.message });
  }
});

// POST /api/categorias -> Solo Admin: crear una nueva categoría
router.post('/', verificarToken, soloAdmin, async (req, res) => {
  try {
    const { nombre, descripcion, requiereVisibilidadRestringida } = req.body;
    if (!nombre) return res.status(400).json({ mensaje: 'El nombre es obligatorio' });

    const categoria = new Categoria({ nombre, descripcion, requiereVisibilidadRestringida });
    await categoria.save();
    res.status(201).json(categoria);
  } catch (error) {
    res.status(400).json({ mensaje: mensajeError(error, 'Error al crear categoría'), error: error.message });
  }
});

// PUT /api/categorias/:id -> Solo Admin: editar una categoría
router.put('/:id', verificarToken, soloAdmin, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    const { nombre, descripcion, requiereVisibilidadRestringida } = req.body;
    const categoria = await Categoria.findByIdAndUpdate(
      req.params.id,
      { nombre, descripcion, requiereVisibilidadRestringida },
      { new: true, runValidators: true }
    );
    if (!categoria) return res.status(404).json({ mensaje: 'Categoría no encontrada' });
    res.json(categoria);
  } catch (error) {
    res.status(400).json({ mensaje: mensajeError(error, 'Error al actualizar categoría'), error: error.message });
  }
});

// DELETE /api/categorias/:id -> Solo Admin: eliminar una categoría
router.delete('/:id', verificarToken, soloAdmin, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ mensaje: 'Identificador no válido' });
    }
    // No se puede borrar una categoría que ya tiene incidencias registradas
    if (await Incidencia.exists({ categoria: req.params.id })) {
      return res.status(400).json({
        mensaje: 'No se puede eliminar: ya hay incidencias registradas con esta categoría'
      });
    }
    const categoria = await Categoria.findByIdAndDelete(req.params.id);
    if (!categoria) return res.status(404).json({ mensaje: 'Categoría no encontrada' });
    res.json({ mensaje: 'Categoría eliminada correctamente' });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al eliminar la categoría', error: error.message });
  }
});

module.exports = router;
