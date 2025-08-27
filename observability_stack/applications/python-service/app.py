from flask import Flask, request, jsonify
import requests
import time
import random
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import Resource
from prometheus_client import Counter, Histogram, generate_latest
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

resource = Resource.create({
    "service.name": "python-flask-service",
    "service.version": "1.0.0",
    "deployment.environment": "production"
})

trace.set_tracer_provider(TracerProvider(resource=resource))
tracer = trace.get_tracer(__name__)
otlp_exporter = OTLPSpanExporter(endpoint="http://otel-collector.tracing.svc.cluster.local:4317", insecure=True)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status_code'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
ERROR_COUNT = Counter('application_errors_total', 'Total errors', ['error_type'])

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    REQUEST_COUNT.labels(request.method, request.endpoint or 'unknown', response.status_code).inc()
    if hasattr(request, 'start_time'):
        REQUEST_DURATION.labels(request.method, request.endpoint or 'unknown').observe(time.time() - request.start_time)
    return response

@app.route('/')
def home():
    with tracer.start_as_current_span("home_handler"):
        logger.info("Home endpoint called")
        return jsonify({"service": "python-flask-service", "status": "healthy", "timestamp": time.time()})

@app.route('/api/data')
def get_data():
    with tracer.start_as_current_span("get_data_handler") as span:
        processing_time = random.uniform(0.1, 0.5)
        time.sleep(processing_time)
        span.set_attribute("processing_time", processing_time)
        try:
            child_span = tracer.start_span("call_nodejs_service")
            nodejs_response = requests.get("http://nodejs-service:3000/api/info", timeout=5)
            child_span.set_attribute("http.status_code", nodejs_response.status_code)
            nodejs_data = nodejs_response.json() if nodejs_response.status_code == 200 else {"error": "Service unavailable"}
        except Exception as e:
            ERROR_COUNT.labels("nodejs_service_error").inc()
            logger.error(f"Error calling Node.js service: {e}")
            nodejs_data = {"error": "Service unavailable"}
        data = {
            "python_data": {"message": "Data from Python service", "processing_time": processing_time, "random_number": random.randint(1,100)},
            "nodejs_data": nodejs_data
        }
        logger.info(f"Data endpoint called, processing time: {processing_time}")
        return jsonify(data)

@app.route('/api/error')
def simulate_error():
    with tracer.start_as_current_span("simulate_error") as span:
        ERROR_COUNT.labels("simulated_error").inc()
        span.record_exception(Exception("Simulated error for testing"))
        return jsonify({"error": "Simulated error for testing"}), 500

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "python-flask-service"})

@app.route('/metrics')
def metrics():
    return generate_latest()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
