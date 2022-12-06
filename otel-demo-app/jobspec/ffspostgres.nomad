job "ffspostgres" {

  datacenters = ["dc1"]
  type        = "service"

  group "ffspostgres" {
    restart {
      attempts = 10
      interval = "5m"
      delay    = "10s"
      mode     = "delay"
    }

    network {
      
      port "db" {
        static = 5432
      }
    }

    task "ffspostgres" {
      driver = "docker"

      config {
        image = "postgres:14"
        ports = ["db"]
      }
      env {
        POSTGRES_DB = "ffs"
        POSTGRES_PASSWORD = "ffs"
        POSTGRES_USER = "ffs"
        OTEL_SERVICE_NAME = "ffspostgres"
      }

      template {
        data = <<EOF
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

      service {
        name = "ffspostgres-service"
        port = "db"

        check {
          interval = "10s"
          timeout  = "5s"
          type     = "script"
          command  = "pg_isready"
          args     = [
            "-d", "ffs",
            "-h", "${NOMAD_IP_db}",
            "-p", "${NOMAD_PORT_db}",
            "-U", "ffs"
          ]
        }
      }

    }
  }
}