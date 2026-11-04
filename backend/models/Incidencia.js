const mongoose = require('mongoose');

const incidenciaSchema = new mongoose.Schema({
  titulo: {
    type: String,
    required: [true, 'El título es obligatorio'],
    trim: true
  },
  descripcion: {
    type: String,
    required: [true, 'La descripción es obligatoria'],
    trim: true
  },
  categoria: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Categoria',
    required: [true, 'La categoría es obligatoria']
  },
  ubicacion: {
    type: String,
    required: [true, 'La ubicación es obligatoria'],
    trim: true
  },
  estado: {
    type: String,
    enum: ['pendiente', 'en_proceso', 'resuelta'],
    default: 'pendiente'
  },
  prioridad: {
    type: String,
    enum: ['baja', 'media', 'alta'],
    default: 'media'
  },
  // Quién reportó la incidencia
  usuario: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    required: true
  },
  // Fechas para el control de tiempos de respuesta
  fechaCreacion: { type: Date, default: Date.now },
  fechaRespuesta: { type: Date, default: null },   // primera vez que sale de "pendiente"
  fechaResolucion: { type: Date, default: null },  // cuando pasa a "resuelta"
  // Mensaje del Admin visible para quien reportó (seguimiento)
  observacionAdmin: { type: String, default: '' }
});

module.exports = mongoose.model('Incidencia', incidenciaSchema);
