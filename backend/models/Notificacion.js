const mongoose = require('mongoose');

const notificacionSchema = new mongoose.Schema({
  // A quién va dirigida
  usuario: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    required: true
  },
  mensaje: { type: String, required: true },
  tipo: { type: String, enum: ['incidencia', 'servicio'], required: true },
  referencia: { type: mongoose.Schema.Types.ObjectId, default: null },
  leida: { type: Boolean, default: false },
  fecha: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Notificacion', notificacionSchema);
