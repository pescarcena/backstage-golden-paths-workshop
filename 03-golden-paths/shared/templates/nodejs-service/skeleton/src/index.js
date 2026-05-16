const express = require('express');

const app = express();
const PORT = process.env.PORT || ${{ values.port }};

app.use(express.json());

// Endpoint de salud para Kubernetes
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: '${{ values.name }}' });
});

// Endpoint de informacion
app.get('/', (req, res) => {
  res.json({
    service: '${{ values.name }}',
    version: '1.0.0',
    description: '${{ values.description }}',
  });
});

app.listen(PORT, () => {
  console.log(`Servicio ${{ values.name }} escuchando en puerto ${PORT}`);
});
