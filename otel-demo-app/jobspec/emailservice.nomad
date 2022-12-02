job "emailservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "emailservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 6060
      }
    }

    service {
      name = "emailservice"
      // provider = "nomad"
      // tags = [
      //   "traefik.http.routers.emailservice.rule=Host(`emailservice.localhost`)",
      //   "traefik.http.routers.emailservice.entrypoints=web",
      //   "traefik.http.routers.emailservice.tls=false",
      //   "traefik.enable=true",
      // ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "emailservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-emailservice"

        ports = ["containerport"]
      }
      env {
        APP_ENV = "production"
        EMAIL_SERVICE_PORT = "6060"
        // OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-http.localhost/v1/traces"
        OTEL_SERVICE_NAME = "emailservice"
      }

      template {
        data = <<EOF
{{ range service "otelcol-http" }}
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}/v1/traces"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 75
        memory = 150
      }

    }
  }
}