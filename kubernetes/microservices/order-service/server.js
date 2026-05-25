const express = require('express');
const client = require('prom-client');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

// In-memory order store (replace with Aurora PostgreSQL in production)
const orders = new Map();

// Prometheus metrics
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.2, 0.5, 1, 2, 5]
});
register.registerMetric(httpRequestDuration);

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code', 'service']
});
register.registerMetric(httpRequestsTotal);

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    httpRequestDuration.observe(
      { method: req.method, route, status_code: res.statusCode },
      duration
    );
    httpRequestsTotal.inc({
      method: req.method,
      route,
      status_code: res.statusCode,
      service: 'order-service'
    });
  });
  next();
});

// OpenTelemetry trace context propagation
app.use((req, res, next) => {
  const traceparent = req.headers['traceparent'] || `00-${Array(32).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('')}-${Array(16).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('')}-01`;
  req.traceId = traceparent.split('-')[1];
  res.setHeader('traceparent', traceparent);
  next();
});

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'order-service', traceId: req.traceId });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Create Order
app.post('/api/orders', (req, res) => {
  const { items, shippingAddress, paymentMethod } = req.body;
  const orderId = `ORD-${uuidv4().split('-')[0].toUpperCase()}`;

  const order = {
    orderId,
    items,
    shippingAddress,
    paymentMethod,
    status: 'pending',
    createdAt: new Date().toISOString()
  };

  orders.set(orderId, order);

  res.status(201).json({
    orderId,
    status: 'pending',
    message: 'Order created successfully',
    traceId: req.traceId
  });
});

// Get Order
app.get('/api/orders/:id', (req, res) => {
  const order = orders.get(req.params.id);
  if (!order) {
    return res.status(404).json({ error: 'Order not found', traceId: req.traceId });
  }
  res.json({ ...order, traceId: req.traceId });
});

app.listen(PORT, () => {
  console.log(`Order service running on port ${PORT}`);
});
