const mongoose = require('mongoose');

const usuarioSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: [true, 'El nombre es obligatorio'],
    trim: true
  },
  correo: {
    type: String,
    required: [true, 'El correo es obligatorio'],
    unique: true,
    lowercase: true,
    trim: true
  },
  contrasena: {
    type: String,
    required: [true, 'La contraseña es obligatoria']
  },
  rol: {
    type: String,
    enum: ['admin', 'general'],
    default: 'general'
  },
  fechaRegistro: {
    type: Date,
    default: Date.now
  }
});

// Nunca devolver la contraseña cuando el usuario se convierte a JSON
usuarioSchema.methods.toJSON = function () {
  const usuario = this.toObject();
  delete usuario.contrasena;
  return usuario;
};

module.exports = mongoose.model('Usuario', usuarioSchema);
