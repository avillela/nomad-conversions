job "loadgenerator" {
  type        = "service"
  datacenters = ["dc1"]

  group "loadgenerator" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 8089
      }
    }

    service {
      name = "loadgenerator"
      // provider = "nomad"
      // tags = [
      //   "traefik.http.routers.loadgenerator.rule=Host(`loadgenerator.localhost`)",
      //   "traefik.http.routers.loadgenerator.entrypoints=web",
      //   "traefik.http.routers.loadgenerator.tls=false",
      //   "traefik.enable=true",
      // ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "loadgenerator" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-loadgenerator"
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
        LOCUST_AUTOSTART = "true"
        LOCUST_HEADLESS = "false"
        // LOCUST_HOST = "http://frontend.localhost"
        LOCUST_USERS = "10"
        LOCUST_WEB_PORT = "8089"
        LOADGENERATOR_PORT = "8089"
        // OTEL_EXPORTER_OTLP_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_SERVICE_NAME = "loadgenerator"
        PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION = "python"
      }

      template {
        data = <<EOF
{{ range service "frontend" }}
FRONTEND_ADDR = "{{ .Address }}:{{ .Port }}"
LOCUST_HOST = "http://{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
        change_mode   = "noop"
      }


      resources {
        cpu    = 55
        memory = 1024
        memory_max = 2048
      }

    }
  }
}