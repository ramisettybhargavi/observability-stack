package com.observability.controller;

import com.observability.service.DataService;
import io.micrometer.core.annotation.Timed;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@RestController
@RequestMapping("/api")
public class ServiceController {

    private static final Logger logger = LoggerFactory.getLogger(ServiceController.class);
    
    @Autowired
    private DataService dataService;
    
    @Autowired
    private Tracer tracer;
    
    private final Counter requestCounter;
    private final Counter errorCounter;

    public ServiceController(MeterRegistry meterRegistry) {
        this.requestCounter = Counter.builder("http_requests_total")
                .description("Total HTTP requests")
                .register(meterRegistry);
        this.errorCounter = Counter.builder("application_errors_total")
                .description("Total application errors")
                .register(meterRegistry);
    }

    @GetMapping("/")
    @Timed(value = "http_request_duration", description = "Time taken to serve HTTP request")
    public ResponseEntity<Map<String, Object>> home() {
        Span span = tracer.spanBuilder("home_handler").startSpan();
        try {
            span.setAttribute("http.method", "GET");
            span.setAttribute("http.url", "/api/");
            requestCounter.increment();
            logger.info("Home endpoint called");
            return ResponseEntity.ok(Map.of(
                "service", "java-spring-boot-service",
                "status", "healthy",
                "timestamp", Instant.now().toEpochMilli()
            ));
        } finally {
            span.end();
        }
    }

    @GetMapping("/process")
    @Timed(value = "process_request_duration", description = "Time taken to process request")
    public ResponseEntity<Map<String, Object>> processData() {
        Span span = tracer.spanBuilder("process_data_handler").startSpan();

        try {
            span.setAttribute("http.method", "GET");
            span.setAttribute("http.url", "/api/process");
            requestCounter.increment();

            // Simulate processing time
            int processingTime = ThreadLocalRandom.current().nextInt(100, 500);
            try {
                Thread.sleep(processingTime);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Processing interrupted", e);
            }

            span.setAttribute("processing_time", processingTime);
            Map<String, Object> processedData = dataService.processData();

            Map<String, Object> response = Map.of(
                "message", "Data processed by Java Spring Boot service",
                "processing_time", processingTime,
                "data", processedData,
                "timestamp", Instant.now().toEpochMilli()
            );

            logger.info("Process endpoint called, processing time: {}ms", processingTime);
            return ResponseEntity.ok(response);

        } finally {
            span.end();
        }
    }

    @GetMapping("/error")
    public ResponseEntity<Map<String, Object>> simulateError() {
        Span span = tracer.spanBuilder("simulate_error").startSpan();

        try {
            span.setAttribute("http.method", "GET");
            span.setAttribute("http.url", "/api/error");
            errorCounter.increment();
            
            RuntimeException error = new RuntimeException("Simulated error for testing");
            span.recordException(error);
            span.setStatus(io.opentelemetry.api.trace.StatusCode.ERROR, "Simulated error");

            logger.error("Simulated error endpoint called");

            return ResponseEntity.status(500).body(Map.of(
                "error", "Simulated error for testing",
                "timestamp", Instant.now().toEpochMilli()
            ));
        } finally {
            span.end();
        }
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
            "status", "healthy",
            "service", "java-spring-boot-service"
        ));
    }
}
