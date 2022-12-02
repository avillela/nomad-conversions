job "checkoutservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "checkoutservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 5050
      }
    }

    service {
      name = "checkoutservice"
      // provider = "nomad"
      // tags = [
      //   "traefik.http.routers.checkoutservice.rule=Host(`checkoutservice.localhost`)",
      //   "traefik.http.routers.checkoutservice.entrypoints=web",
      //   "traefik.http.routers.checkoutservice.tls=false",
      //   "traefik.enable=true",
      // ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "checkoutservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-checkoutservice"

        ports = ["containerport"]
      }
      env {
        // CART_SERVICE_ADDR = "cartservice.localhost"
        CHECKOUT_SERVICE_PORT = "5050"
        // CURRENCY_SERVICE_ADDR = "currencyservice.localhost"
        // EMAIL_SERVICE_ADDR = "http://emailservice.localhost"
        // OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
        // OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_SERVICE_NAME = "checkoutservice"
        // PAYMENT_SERVICE_ADDR = "paymentservice.localhost"
        // PRODUCT_CATALOG_SERVICE_ADDR = "productcatalogservice.localhost"
        // SHIPPING_SERVICE_ADDR = "shippingservice.localhost"
      }

      template {
        data = <<EOF
{{ range service "cartservice" }}
CART_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "currencyservice" }}
CURRENCY_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "emailservice" }}
EMAIL_SERVICE_ADDR = "http://{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "paymentservice" }}
PAYMENT_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "productcatalogservice" }}
PRODUCT_CATALOG_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "shippingservice" }}
SHIPPING_SERVICE_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }


      resources {
        cpu    = 75
        memory = 100
      }
    }
  }
}