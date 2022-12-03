job "recommendationservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "recommendationservice" {
    count = 1

    update {
      healthy_deadline  = "20m"
      progress_deadline = "25m"
    }

    network {
      mode = "host"

      port "containerport" {
        to = 9001
      }
    }

    service {
      name = "recommendationservice"
      // provider = "nomad"
      // tags = [
      //   "traefik.http.routers.recommendationservice.rule=Host(`recommendationservice.localhost`)",
      //   "traefik.http.routers.recommendationservice.entrypoints=web",
      //   "traefik.http.routers.recommendationservice.tls=false",
      //   "traefik.enable=true",
      // ]

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
        // https://developer.hashicorp.com/nomad/docs/drivers/docker#image_pull_timeout
        image_pull_timeout = "15m"
        ports = ["containerport"]
      }

      // https://developer.hashicorp.com/nomad/docs/job-specification/restart#restart-parameters
      restart {
        attempts = 5
        delay    = "15s"
      }
      env {
        // FEATURE_FLAG_GRPC_SERVICE_ADDR = "featureflagservice.localhost"
        // OTEL_EXPORTER_OTLP_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
        OTEL_METRICS_EXPORTER = "otlp"
        OTEL_PYTHON_LOG_CORRELATION = "true"
        OTEL_SERVICE_NAME = "recommendationservice"
        OTEL_TRACES_EXPORTER = "otlp"
        // PRODUCT_CATALOG_SERVICE_ADDR = "productcatalogservice.localhost"
        PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION = "python"
        RECOMMENDATION_SERVICE_PORT = "9001"
      }

      template {
        data = <<EOF
{{ range service "featureflagservice-grpc" }}
FEATURE_FLAG_GRPC_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "productcatalogservice" }}
PRODUCT_CATALOG_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 55
        memory = 100
      }

    }
  }
}