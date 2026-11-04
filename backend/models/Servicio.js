const mongoose = require('mongoose');

const servicioSchema = new mongoose.Schema({
  tipoServicio: {
    type: String,
    required: [true, 'El tipo de servicio es obligatorio'],
    trim: true
  },
  descripcion: { type: String, trim: true, default: '' },
  // Fecha en la que se quiere recibir el servicio (opcional)
  fechaProgramada: { type: Date, default: null },
  estado: {
    type: String,
    enum: ['pendiente', 'en_proceso', 'completado', 'rechazado'],
    default: 'pendiente'
  },
  usuario: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    required: true
  },
  fechaSolicitud: { type: Date, default: Date.now },
  observacionAdmin: { type: String, default: '' }
});

module.exports = mongoose.model('Servicio', servicioSchema);
