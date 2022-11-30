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
      provider = "nomad"
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

        ports = ["containerport"]
      }
      env {
        ENVOY_PORT = "8080"
        ENVOY_UID = "0"
        FEATURE_FLAG_SERVICE_HOST = "feature-flag-service.localhost"
        FEATURE_FLAG_SERVICE_PORT = "80"
        FRONTEND_HOST = "frontend.localhost"
        FRONTEND_PORT = "80"
        GRAFANA_SERVICE_HOST = "grafana.localhost"
        GRAFANA_SERVICE_PORT = "80"
        JAEGER_SERVICE_HOST = "jaeger.localhost"
        JAEGER_SERVICE_PORT = "80"
        LOCUST_WEB_HOST = "loadgenerator.localhost"
        LOCUST_WEB_PORT = "80"
        PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-http.localhost/v1/traces"
      }      

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}