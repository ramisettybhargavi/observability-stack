const { NodeSDK } = require('@opentelemetry/sdk-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-grpc');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const resource = new Resource({
  [SemanticResourceAttributes.SERVICE_NAME]: "nodejs-service",
  [SemanticResourceAttributes.SERVICE_VERSION]: "1.0.0",
  [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: "production"
});

const sdk = new NodeSDK({
  resource: resource,
  traceExporter: new OTLPTraceExporter({
    url: "http://otel-collector.tracing.svc.cluster.local:4317"
  }),
  instrumentations: [getNodeAutoInstrumentations()]
});

sdk.start();
