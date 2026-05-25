import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';

// Custom metrics
const checkoutLatency = new Trend('checkout_latency');
const errorRate = new Rate('errors');
const successfulCheckouts = new Counter('successful_checkouts');

export const options = {
  stages: [
    { duration: '2m', target: 10000 },
    { duration: '5m', target: 50000 },
    { duration: '2m', target: 100000 },
    { duration: '5m', target: 100000 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],
    http_req_failed: ['rate<0.001'],
    checkout_latency: ['p(95)<500'],
    errors: ['rate<0.001'],
    iterations_per_second: ['rate>500'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'https://whitefriday.example.com';

export default function () {
  group('Homepage Load', () => {
    const res = http.get(`${BASE_URL}/`);
    const success = check(res, {
      'homepage status is 200': (r) => r.status === 200,
      'homepage load time < 200ms': (r) => r.timings.duration < 200,
    });
    errorRate.add(!success);
  });

  sleep(1);

  group('Product Search', () => {
    const searchTerm = ['laptop', 'phone', 'shoes', 'watch', 'camera'][Math.floor(Math.random() * 5)];
    const res = http.get(`${BASE_URL}/api/products/search?q=${searchTerm}&limit=20`);
    const success = check(res, {
      'search status is 200': (r) => r.status === 200,
      'search response time < 200ms': (r) => r.timings.duration < 200,
      'search returns products': (r) => JSON.parse(r.body).products.length > 0,
    });
    errorRate.add(!success);
  });

  sleep(1);

  const productId = Math.floor(Math.random() * 10000) + 1;

  group('View Product', () => {
    const res = http.get(`${BASE_URL}/api/products/${productId}`);
    const success = check(res, {
      'product detail status is 200': (r) => r.status === 200,
      'product detail response time < 200ms': (r) => r.timings.duration < 200,
    });
    errorRate.add(!success);
  });

  sleep(1);

  group('Add to Cart', () => {
    const payload = JSON.stringify({
      productId: productId,
      quantity: Math.floor(Math.random() * 3) + 1,
    });
    const res = http.post(`${BASE_URL}/api/cart/items`, payload, {
      headers: { 'Content-Type': 'application/json' },
    });
    const success = check(res, {
      'add to cart status is 200/201': (r) => r.status === 200 || r.status === 201,
      'add to cart response time < 200ms': (r) => r.timings.duration < 200,
    });
    errorRate.add(!success);
  });

  sleep(1);

  group('Checkout Flow', () => {
    const start = Date.now();
    const res = http.post(`${BASE_URL}/api/orders`, JSON.stringify({
      items: [{ productId: productId, quantity: 1 }],
      shippingAddress: { city: 'Riyadh', country: 'SA' },
      paymentMethod: 'credit_card',
    }), {
      headers: { 'Content-Type': 'application/json' },
    });
    const duration = Date.now() - start;
    checkoutLatency.add(duration);

    const success = check(res, {
      'checkout status is 200/201': (r) => r.status === 200 || r.status === 201,
      'checkout latency < 500ms': () => duration < 500,
    });
    errorRate.add(!success);
    if (success) successfulCheckouts.add(1);
  });

  sleep(1);

  group('Payment Callback', () => {
    const res = http.post(`${BASE_URL}/api/payments/callback`, JSON.stringify({
      orderId: `ORD-${Math.random().toString(36).substr(2, 9)}`,
      status: 'success',
      transactionId: `TXN-${Math.random().toString(36).substr(2, 9)}`,
    }), {
      headers: { 'Content-Type': 'application/json' },
    });
    const success = check(res, {
      'payment callback status is 200': (r) => r.status === 200,
      'payment callback response time < 200ms': (r) => r.timings.duration < 200,
    });
    errorRate.add(!success);
  });

  sleep(Math.random() * 2);
}
