job "jaeger" {
  datacenters = ["dc1"]

  group "jaeger" {
    count = 1

    network {
      mode = "bridge"

      port "jaeger-ui" {
        to = 16686
      }
      port "jaeger-collector" {
        to = 14268
      }

      port "jaeger-proto" {
        to = 14250
      }

      port "jaeger-grpc" {
        to = 16685
      }

    }

    service {
      name = "jaeger-proto"
      tags = [
        "traefik.tcp.routers.jaeger-proto.rule=HostSNI(`*`)",
        "traefik.tcp.routers.jaeger-proto.entrypoints=grpc",
        "traefik.enable=true",
      ]        

      port = "jaeger-proto"
    }

    service {
      name = "jaeger-grpc"
      tags = [
        "traefik.tcp.routers.jaeger-grpc.rule=HostSNI(`*`)",
        "traefik.tcp.routers.jaeger-grpc.entrypoints=grpc",
        "traefik.enable=true",
      ]        

      port = "jaeger-grpc"
    }

    service {
      name = "jaeger-ui"
      tags = [
        "traefik.http.routers.jaeger-ui.rule=Host(`jaeger-ui.localhost`)",
        "traefik.http.routers.jaeger-ui.entrypoints=web",
        "traefik.http.routers.jaeger-ui.tls=false",
        "traefik.enable=true",
      ]

      port = "jaeger-ui"
    }


    task "jaeger" {
      driver = "docker"

      config {
        image = "jaegertracing/all-in-one:1.35.1"
        // image = "jaegertracing/all-in-one:1.33"
        ports = ["jaeger-ui", "jaeger-collector"]
      }

      env {
        SPAN_STORAGE_TYPE = "memory"
      }

      resources {
        cpu    = 100
        memory = 512
      }
    }
  }
}