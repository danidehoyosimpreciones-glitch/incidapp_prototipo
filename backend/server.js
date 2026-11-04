require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const usuarioRoutes = require('./routes/usuarios');
const categoriaRoutes = require('./routes/categorias');
const incidenciaRoutes = require('./routes/incidencias');
const servicioRoutes = require('./routes/servicios');
const notificacionRoutes = require('./routes/notificaciones');

const app = express();

app.use(cors());
app.use(express.json());

// Rutas
app.use('/api/auth', authRoutes);
app.use('/api/usuarios', usuarioRoutes);
app.use('/api/categorias', categoriaRoutes);
app.use('/api/incidencias', incidenciaRoutes);
app.use('/api/servicios', servicioRoutes);
app.use('/api/notificaciones', notificacionRoutes);

app.get('/', (req, res) => {
  res.json({ mensaje: 'API de IncidApp funcionando correctamente' });
});

// Ruta que no existe
app.use((req, res) => {
  res.status(404).json({ mensaje: 'Ruta no encontrada' });
});

// Cualquier error inesperado responde con JSON en vez de tumbar el servidor
app.use((error, req, res, next) => {
  console.error(error);
  res.status(500).json({ mensaje: 'Error interno del servidor' });
});

// Si algo falla sin ser capturado, se registra pero el servidor sigue vivo
process.on('unhandledRejection', (error) => {
  console.error('Promesa no controlada:', error);
});

const PORT = process.env.PORT || 3000;

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('Conectado a MongoDB');
    app.listen(PORT, () => console.log(`Servidor corriendo en http://localhost:${PORT}`));
  })
  .catch((error) => {
    console.error('Error al conectar a MongoDB:', error.message);
  });
