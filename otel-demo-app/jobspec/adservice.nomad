job "adservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "adservice" {
    count = 1

    update {
      healthy_deadline  = "20m"
      progress_deadline = "25m"
    }

    network {
      mode = "host"

      port "containerport" {
        to = 9555
      }
    }

    service {
      name = "adservice"
      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "adservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-adservice"
        image_pull_timeout = "25m"
        ports = ["containerport"]
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      env {
          AD_SERVICE_PORT = "${NOMAD_PORT_containerport}"
          OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
          OTEL_SERVICE_NAME = "adservice"
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
        cpu    = 60
        memory = 450
        memory_max = 650
      }

    }
  }
}