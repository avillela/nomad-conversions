job "cartservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "cartservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 7070
      }
    }

    service {
      name = "cartservice"
      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "cartservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-cartservice"
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
        ASPNETCORE_URLS = "http://*:${NOMAD_PORT_containerport}"
        CART_SERVICE_PORT = "${NOMAD_PORT_containerport}"
        OTEL_SERVICE_NAME = "cartservice"
      }

      template {
        data = <<EOF
{{ range service "redis-service" }}
REDIS_ADDR = "{{ .Address }}:{{ .Port }}"
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
        memory = 300
      }

    }
  }
}