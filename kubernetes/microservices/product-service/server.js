const express = require('express');
const client = require('prom-client');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

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
      service: 'product-service'
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
  res.status(200).json({ status: 'ok', service: 'product-service', traceId: req.traceId });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Product Search
app.get('/api/products/search', (req, res) => {
  const { q, limit = 20 } = req.query;
  const products = Array.from({ length: parseInt(limit) }, (_, i) => ({
    id: i + 1,
    name: `${q} Item ${i + 1}`,
    price: Math.floor(Math.random() * 1000) + 50,
    currency: 'SAR'
  }));
  res.json({ products, query: q, total: products.length, traceId: req.traceId });
});

// Product Detail
app.get('/api/products/:id', (req, res) => {
  const productId = parseInt(req.params.id);
  res.json({
    id: productId,
    name: `Product ${productId}`,
    price: Math.floor(Math.random() * 1000) + 50,
    currency: 'SAR',
    inStock: Math.random() > 0.1,
    traceId: req.traceId
  });
});

app.listen(PORT, () => {
  console.log(`Product service running on port ${PORT}`);
});
