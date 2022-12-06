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
      // provider = "nomad"
      // tags = [
      //   "traefik.http.routers.cartservice.rule=Host(`cartservice.localhost`)",
      //   "traefik.http.routers.cartservice.entrypoints=web",
      //   "traefik.http.routers.cartservice.tls=false",
      //   "traefik.enable=true",
      // ]

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
        ASPNETCORE_URLS = "http://*:7070"
        CART_SERVICE_PORT = "7070"
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