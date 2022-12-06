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
        APP_ENV = "production"
        EMAIL_SERVICE_PORT = "${NOMAD_PORT_containerport}"
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
        cpu    = 55
        memory = 150
      }

    }
  }
}