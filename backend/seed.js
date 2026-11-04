// Carga las categorías de incidencias definidas en el proyecto.
// Ejecutar UNA vez con:  npm run seed
// Es seguro repetirlo: solo crea las que no existan, no toca ni duplica las demás.
require('dotenv').config();
const mongoose = require('mongoose');
const Categoria = require('./models/Categoria');

const CATEGORIAS = [
  {
    nombre: 'Estructurales',
    descripcion: 'Daños en techos, paredes, pisos y ventanas del edificio',
    requiereVisibilidadRestringida: false
  },
  {
    nombre: 'Eléctricas',
    descripcion: 'Fallas de luz, cableado y tomacorrientes',
    requiereVisibilidadRestringida: false
  },
  {
    nombre: 'Mantenimiento',
    descripcion: 'Daños en mobiliario y equipos: sillas, mesas, puertas, proyectores',
    requiereVisibilidadRestringida: false
  },
  {
    nombre: 'Limpieza',
    descripcion: 'Áreas sucias o acumulación de basura',
    requiereVisibilidadRestringida: false
  },
  {
    nombre: 'Seguridad',
    descripcion: 'Accesos, cámaras y situaciones de riesgo',
    requiereVisibilidadRestringida: false
  },
  {
    nombre: 'Convivencia',
    descripcion: 'Peleas y bullying. Visibilidad restringida: solo la ve la administración',
    requiereVisibilidadRestringida: true
  }
];

async function main() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    for (const { nombre, ...resto } of CATEGORIAS) {
      const r = await Categoria.updateOne({ nombre }, { $setOnInsert: resto }, { upsert: true });
      console.log(r.upsertedCount ? `Creada:      ${nombre}` : `Ya existía:  ${nombre}`);
    }
    console.log('Listo.');
  } catch (error) {
    console.error('Error al cargar las categorías:', error.message);
  } finally {
    await mongoose.disconnect();
  }
}

main();
