job "frontendproxy" {
  type        = "service"
  datacenters = ["dc1"]

  group "frontendproxy" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 8080
      }

    }

    service {
      name = "frontendproxy"
      tags = [
        "traefik.http.routers.frontendproxy.rule=Host(`otel-demo.localhost`)",
        "traefik.http.routers.frontendproxy.entrypoints=web",
        "traefik.http.routers.frontendproxy.tls=false",
        "traefik.enable=true",
      ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "frontendproxy" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-frontendproxy"
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
        ENVOY_PORT = "${NOMAD_PORT_containerport}"
        ENVOY_UID = "0"
        // GRAFANA_SERVICE_HOST = "grafana.localhost"
        // GRAFANA_SERVICE_PORT = "80"
        // JAEGER_SERVICE_HOST = "jaeger.localhost"
        // JAEGER_SERVICE_PORT = "80"
      }

      template {
        data = <<EOF
{{ range service "grafana" }}
GRAFANA_SERVICE_HOST = "{{ .Address }}"
GRAFANA_SERVICE_PORT = "{{ .Port }}"
{{ end }}

{{ range service "jaeger-frontend" }}
JAEGER_SERVICE_HOST = "{{ .Address }}"
JAEGER_SERVICE_PORT = "{{ .Port }}"
{{ end }}

{{ range service "featureflagservice-http" }}
FEATURE_FLAG_SERVICE_HOST = "{{ .Address }}"
FEATURE_FLAG_SERVICE_PORT = "{{ .Port }}"
{{ end }}

{{ range service "frontend" }}
FRONTEND_HOST = "{{ .Address }}"
FRONTEND_PORT = "{{ .Port }}"
{{ end }}

{{ range service "loadgenerator" }}
LOCUST_WEB_HOST = "{{ .Address }}"
LOCUST_WEB_PORT = "{{ .Port }}"
{{ end }}

{{ range service "otelcol-http" }}
PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}/v1/traces"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 55
        memory = 1024
        memory_max = 2048
      }

    }
  }
}