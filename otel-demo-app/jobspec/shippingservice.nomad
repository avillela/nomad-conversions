job "shippingservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "shippingservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 50050
      }
    }

    service {
      name = "shippingservice"
      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "shippingservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-shippingservice"
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
        OTEL_SERVICE_NAME = "shippingservice"
        SHIPPING_SERVICE_PORT = "${NOMAD_PORT_containerport}"
      }

      template {
        data = <<EOF
{{ range service "quoteservice" }}
QUOTE_SERVICE_ADDR = "http://{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 55
        memory = 75
      }

    }
  }
}