job "jaeger" {
  datacenters = ["dc1"]

  group "jaeger" {
    count = 1

    network {
      mode = "bridge"

      port "frontend" {
        to = 16686
      }
      port "collector" {
        to = 4317
      }

    }

    service {
      name = "jaeger-collector"
      tags = [
        "traefik.tcp.routers.jaeger-grpc.rule=HostSNI(`*`)",
        "traefik.tcp.routers.jaeger-grpc.entrypoints=grpc",
        "traefik.enable=true",
      ]        

      port = "collector"
    }

    service {
      name = "jaeger-frontend"
      tags = [
        "traefik.http.routers.jaeger-ui.rule=Host(`jaeger-ui.localhost`)",
        "traefik.http.routers.jaeger-ui.entrypoints=web",
        "traefik.http.routers.jaeger-ui.tls=false",
        "traefik.enable=true",
      ]

      port = "frontend"
    }


    task "jaeger" {
      driver = "docker"

      config {
        image = "jaegertracing/all-in-one:latest"
        args = [
            "--memory.max-traces", "10000",
            "--query.base-path", "/jaeger/ui"          
        ]
        ports = ["frontend", "collector"]
      }

      env {
        COLLECTOR_OTLP_ENABLED = "true"
      }

      resources {
        cpu    = 100
        memory = 512
      }
    }
  }
}