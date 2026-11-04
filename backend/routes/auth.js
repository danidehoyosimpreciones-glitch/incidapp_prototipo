const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Usuario = require('../models/Usuario');

const router = express.Router();

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { nombre, correo, contrasena, rol } = req.body;

    if (!nombre || !correo || !contrasena) {
      return res.status(400).json({ mensaje: 'Nombre, correo y contraseña son obligatorios' });
    }

    const existente = await Usuario.findOne({ correo });
    if (existente) {
      return res.status(400).json({ mensaje: 'Ya existe un usuario con ese correo' });
    }

    const contrasenaHash = await bcrypt.hash(contrasena, 10);

    // Por seguridad, solo se permite crear cuentas "general" desde el registro público.
    // Un usuario "admin" se promueve manualmente en la base de datos o desde otro admin.
    const usuario = new Usuario({
      nombre,
      correo,
      contrasena: contrasenaHash,
      rol: rol === 'admin' ? 'general' : (rol || 'general')
    });

    await usuario.save();

    const token = jwt.sign(
      { id: usuario._id, rol: usuario.rol },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({ mensaje: 'Usuario registrado con éxito', token, usuario });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al registrar usuario', error: error.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { correo, contrasena } = req.body;

    if (!correo || !contrasena) {
      return res.status(400).json({ mensaje: 'Correo y contraseña son obligatorios' });
    }

    const usuario = await Usuario.findOne({ correo });
    if (!usuario) {
      return res.status(401).json({ mensaje: 'Credenciales incorrectas' });
    }

    const coincide = await bcrypt.compare(contrasena, usuario.contrasena);
    if (!coincide) {
      return res.status(401).json({ mensaje: 'Credenciales incorrectas' });
    }

    const token = jwt.sign(
      { id: usuario._id, rol: usuario.rol },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({ mensaje: 'Inicio de sesión exitoso', token, usuario });
  } catch (error) {
    res.status(500).json({ mensaje: 'Error al iniciar sesión', error: error.message });
  }
});

module.exports = router;
