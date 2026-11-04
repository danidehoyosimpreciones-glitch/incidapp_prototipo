const Notificacion = require('../models/Notificacion');

// Crea una notificación para un usuario. Si falla, solo lo registra en consola
// para que un error al notificar nunca rompa la operación principal.
async function notificar(usuario, mensaje, tipo, referencia) {
  try {
    await Notificacion.create({ usuario, mensaje, tipo, referencia });
  } catch (error) {
    console.error('No se pudo crear la notificación:', error.message);
  }
}

module.exports = notificar;
