job "productcatalogservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "productcatalogservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 3550
      }
    }

    service {
      name = "productcatalogservice"
      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "productcatalogservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-productcatalogservice"
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
        OTEL_SERVICE_NAME = "productcatalogservice"
        PRODUCT_CATALOG_SERVICE_PORT = "${NOMAD_PORT_containerport}"
      }

      template {
        data = <<EOF
{{ range service "featureflagservice-grpc" }}
FEATURE_FLAG_GRPC_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
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
        memory = 150
      }
    }
  }
}