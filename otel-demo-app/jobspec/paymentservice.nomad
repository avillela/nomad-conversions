job "paymentservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "paymentservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 50051
      }
    }

    service {
      name = "paymentservice"
      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "paymentservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-paymentservice"
        image_pull_timeout = "10m"
        ports = ["containerport"]
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      env {
        OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
        OTEL_SERVICE_NAME = "paymentservice"
        PAYMENT_SERVICE_PORT = "${NOMAD_PORT_containerport}"
      }

      template {
        data = <<EOF
{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 55
        memory = 300
      }

    }
  }
}