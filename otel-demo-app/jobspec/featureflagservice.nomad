job "featureflagservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "featureflagservice" {
    count = 1

    network {
      mode = "host"

      port "http" {
        to = 8081
      }
      port "grpc" {
        to = 50053
      }
    }

    service {
      name = "featureflagservice-http"
      // provider = "nomad"
      // tags = [
      //   "traefik.http.routers.featureflagservice.rule=Host(`featureflagservice.localhost`)",
      //   "traefik.http.routers.featureflagservice.entrypoints=web",
      //   "traefik.http.routers.featureflagservice.tls=false",
      //   "traefik.enable=true",
      // ]

      port = "http"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

    service {
      name = "featureflagservice-grpc"
      // provider = "nomad"
      // tags = [
      //   "traefik.tcp.routers.featureflagservice-grpc.rule=HostSNI(`*`)",
      //   "traefik.tcp.routers.featureflagservice-grpc.entrypoints=grpc",
      //   "traefik.enable=true",
      // ]        
      port = "grpc"
    }

    task "featureflagservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-featureflagservice"
        image_pull_timeout = "10m"
        ports = ["http", "grpc"]
      }

      restart {
        attempts = 4
        delay    = "15s"
      }

      env {
        // DATABASE_URL = "ecto://ffs:ffs@ffspostgres.localhost:7233/ffs"
        FEATURE_FLAG_GRPC_SERVICE_PORT = "50053"
        FEATURE_FLAG_SERVICE_PATH_ROOT = "\"/feature\""
        FEATURE_FLAG_SERVICE_PORT = "8081"
        // OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_EXPORTER_OTLP_TRACES_PROTOCOL = "grpc"
        OTEL_SERVICE_NAME = "featureflagservice"
      }

      template {
        data = <<EOF
{{ range service "ffspostgres-service" }}
DATABASE_URL = "ecto://ffs:ffs@{{ .Address }}:{{ .Port }}/ffs"
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
        memory = 250
      }

    }
  }
}