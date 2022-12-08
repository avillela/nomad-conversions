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
        CHECKOUT_SERVICE_PORT = "${NOMAD_PORT_containerport}"
        OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
        OTEL_SERVICE_NAME = "checkoutservice"
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
        cpu    = 55
        memory = 450
        memory_max = 600
      }
    }
  }
}