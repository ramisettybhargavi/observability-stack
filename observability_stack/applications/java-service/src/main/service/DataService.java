package com.observability.service;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class DataService {

    private static final Logger logger = LoggerFactory.getLogger(DataService.class);

    @Autowired
    private RestTemplate restTemplate;

    @Autowired
    private Tracer tracer;

    public Map<String, Object> processData() {
        Span span = tracer.spanBuilder("process_business_logic").startSpan();
        try {
            span.setAttribute("operation", "process_data");

            Span dbSpan = tracer.spanBuilder("database_operation").startSpan();
            try {
                dbSpan.setAttribute("db.system", "h2");
                dbSpan.setAttribute("db.operation", "SELECT");
                dbSpan.setAttribute("db.table", "users");

                Thread.sleep(ThreadLocalRandom.current().nextInt(20, 100));

                logger.info("Database operation completed");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Database operation interrupted", e);
            } finally {
                dbSpan.end();
            }

            Map<String, Object> externalData = callExternalService();

            return Map.of(
                "processed", true,
                "algorithm_result", ThreadLocalRandom.current().nextInt(1, 1000),
                "external_data", externalData,
                "database_records", ThreadLocalRandom.current().nextInt(10, 50)
            );
        } finally {
            span.end();
        }
    }

    private Map<String, Object> callExternalService() {
        Span span = tracer.spanBuilder("call_nodejs_service").startSpan();
        try {
            span.setAttribute("http.method", "GET");
            span.setAttribute("http.url", "http://nodejs-service:3000/api/info");

            try {
                Object response = restTemplate.getForObject("http://nodejs-service:3000/api/info", Object.class);
                span.setAttribute("http.status_code", 200);
                logger.info("Successfully called Node.js service");
                return Map.of("external_service_data", response);
            } catch (Exception e) {
                span.recordException(e);
                span.setStatus(io.opentelemetry.api.trace.StatusCode.ERROR, e.getMessage());
                logger.error("Error calling Node.js service: {}", e.getMessage());
                return Map.of("external_service_data", "Service unavailable");
            }
        } finally {
            span.end();
        }
    }
}
