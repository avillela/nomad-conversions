job "recommendationservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "recommendationservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 9001
      }
    }

    service {
      provider = "nomad"
      tags = [
        "traefik.http.routers.recommendationservice.rule=Host(`recommendationservice.localhost`)",
        "traefik.http.routers.recommendationservice.entrypoints=web",
        "traefik.http.routers.recommendationservice.tls=false",
        "traefik.enable=true",
      ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "recommendationservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-recommendationservice"

        ports = ["containerport"]
      }
      env {
        FEATURE_FLAG_GRPC_SERVICE_ADDR = "featureflagservice.localhost"
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
        OTEL_METRICS_EXPORTER = "otlp"
        OTEL_PYTHON_LOG_CORRELATION = "true"
        OTEL_SERVICE_NAME = "recommendationservice"
        OTEL_TRACES_EXPORTER = "otlp"
        PRODUCT_CATALOG_SERVICE_ADDR = "productcatalogservice.localhost"
        PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION = "python"
        RECOMMENDATION_SERVICE_PORT = "9001"
      }      

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}