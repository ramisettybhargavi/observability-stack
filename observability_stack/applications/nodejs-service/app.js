require('./instrumentation');
const express = require('express');
const axios = require('axios');
const { trace, context } = require('@opentelemetry/api');
const client = require('prom-client');
const winston = require('winston');

const app = express();
const port = 3000;
const tracer = trace.getTracer('nodejs-service');

const REQUEST_COUNT = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const REQUEST_DURATION = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route']
});

const ERROR_COUNT = new client.Counter({
  name: 'application_errors_total',
  help: 'Total errors',
  labelNames: ['error_type']
});

const logger = winston.createLogger({
  transports: [
    new winston.transports.Console()
  ]
});

app.use(express.json());

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    REQUEST_COUNT.labels(req.method, req.route?.path || req.path, res.statusCode).inc();
    REQUEST_DURATION.labels(req.method, req.route?.path || req.path).observe(duration);
  });
  next();
});

app.get('/', (req, res) => {
  const span = tracer.startSpan('home_handler');
  context.with(trace.setSpan(context.active(), span), () => {
    logger.info("Home endpoint called");
    res.json({ service: "nodejs-service", status: "healthy", timestamp: Date.now() });
    span.end();
  });
});

// Similar endpoint implementations for /api/info, /api/error, /metrics, etc.
// Including instrumentation for external calls and error handling.

app.listen(port, () => {
  logger.info(`Node.js service listening on port ${port}`);
});
