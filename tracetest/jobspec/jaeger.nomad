job "jaeger" {
  datacenters = ["dc1"]

  group "jaeger" {
    count = 1

    network {
      mode = "host"

      port "jaeger-ui" {
        to = 16686
      }
      port "jaeger-collector" {
        to = 4317
      }

      port "jaeger-proto" {
        to = 14250
      }

      port "jaeger-query" {
        to = 16685
      }

    }

    service {
      name = "jaeger-collector"
      port = "jaeger-collector"
    }

    service {
      name = "jaeger-proto"
      port = "jaeger-proto"
    }

    service {
      name = "jaeger-query"
      port = "jaeger-query"
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
        // image = "jaegertracing/all-in-one:1.35.1"
        // image = "jaegertracing/all-in-one:1.33"
        image = "jaegertracing/all-in-one:1.40.0"
        image_pull_timeout = "25m"
        args = [
            "--memory.max-traces", "10000",
            "--query.base-path", "/jaeger/ui"          
        ]
        ports = ["jaeger-ui", "jaeger-collector", "jaeger-query", "jaeger-proto"]
      }

      env {
        SPAN_STORAGE_TYPE = "memory"
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      resources {
        cpu    = 100
        memory = 512
      }
    }
  }
}
