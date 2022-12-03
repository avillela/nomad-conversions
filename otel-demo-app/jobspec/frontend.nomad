job "frontend" {
  type        = "service"
  datacenters = ["dc1"]

  group "frontend" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 8080
      }
    }

    service {
      name = "frontend"
      // provider = "nomad"
      tags = [
        "traefik.http.routers.frontend.rule=Host(`frontend.localhost`)",
        "traefik.http.routers.frontend.entrypoints=web",
        "traefik.http.routers.frontend.tls=false",
        "traefik.enable=true",
      ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "frontend" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-frontend"
        image_pull_timeout = "10m"
        ports = ["containerport"]
      }

      restart {
        attempts = 4
        delay    = "5s"
        interval = "5s"
        mode = "delay"
      }

      env {
        // AD_SERVICE_ADDR = "adservice.localhost"
        // CART_SERVICE_ADDR = "cartservice.localhost"
        // CHECKOUT_SERVICE_ADDR = "checkoutservice.localhost"
        // CURRENCY_SERVICE_ADDR = "currencyservice.localhost"
        ENV_PLATFORM = "local"
        FRONTEND_ADDR = "frontend.localhost"
        // OTEL_EXPORTER_OTLP_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        // OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_RESOURCE_ATTRIBUTES = "service.name=frontend"
        OTEL_SERVICE_NAME = "frontend"
        PORT = "8080"
        // PRODUCT_CATALOG_SERVICE_ADDR = "productcatalogservice.localhost"
        // PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-http.localhost/v1/traces"
        // RECOMMENDATION_SERVICE_ADDR = "recommendationservice.localhost"
        // SHIPPING_SERVICE_ADDR = "shippingservice.localhost"
      }

      template {
        data = <<EOF
{{ range service "adservice" }}
AD_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "cartservice" }}
CART_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "checkoutservice" }}
CHECKOUT_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "currencyservice" }}
CURRENCY_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "productcatalogservice" }}
PRODUCT_CATALOG_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "recommendationservice" }}
RECOMMENDATION_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "shippingservice" }}
SHIPPING_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "otelcol-http" }}
PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}/v1/traces"
{{ end }}

EOF
        destination = "local/env"
        env         = true
        change_mode   = "noop"
      }

      resources {
        cpu    = 55
        memory = 2048
        memory_max = 2048
      }

    }
  }
}