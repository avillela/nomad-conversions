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
      // provider = "nomad"
      name = "frontendproxy"
      tags = [
        "traefik.http.routers.frontendproxy.rule=Host(`frontendproxy.localhost`)",
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
        ENVOY_PORT = "8080"
        ENVOY_UID = "0"
        // FEATURE_FLAG_SERVICE_HOST = "feature-flag-service.localhost"
        // FEATURE_FLAG_SERVICE_PORT = "80"
        // FRONTEND_HOST = "frontend.localhost"
        // FRONTEND_PORT = "80"
        GRAFANA_SERVICE_HOST = "grafana.localhost"
        GRAFANA_SERVICE_PORT = "80"
        JAEGER_SERVICE_HOST = "jaeger.localhost"
        JAEGER_SERVICE_PORT = "80"
        // LOCUST_WEB_HOST = "loadgenerator.localhost"
        // LOCUST_WEB_PORT = "80"
        // PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-http.localhost/v1/traces"
      }

      template {
        data = <<EOF
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
        memory = 500
        memory_max = 1024
      }

    }
  }
}