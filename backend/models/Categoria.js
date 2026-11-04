const mongoose = require('mongoose');

const categoriaSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: [true, 'El nombre de la categoría es obligatorio'],
    unique: true,
    trim: true
  },
  descripcion: {
    type: String,
    trim: true,
    default: ''
  },
  // Categorías como "Convivencia" deben marcarse en true:
  // solo el Admin y el propio reportante pueden ver esas incidencias
  requiereVisibilidadRestringida: {
    type: Boolean,
    default: false
  }
});

module.exports = mongoose.model('Categoria', categoriaSchema);
