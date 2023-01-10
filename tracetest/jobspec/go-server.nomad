job "go-server" {

  datacenters = ["dc1"]

  group "go-server" {
    count = 1


    network {

      port "app-port" {
        to = 9000
        static = 9000
      }

    }

    service {
      name = "go-server"
      tags = [
        "traefik.http.routers.go-server.rule=Host(`go-server.localhost`)",
        "traefik.http.routers.go-server.entrypoints=web",
        "traefik.http.routers.go-server.tls=false",
        "traefik.enable=true",
      ]

      port = "app-port"

    }

    task "go-server" {
      driver = "docker"
      
      config {
        image = "ghcr.io/avillela/go-sample-server:1.0.0"
        force_pull = true
        image_pull_timeout = "20m"
        ports = [
          "app-port",
        ]
      }

      env {
        COLLECTOR_ENDPOINT = "otelcol-http.service.consul:4318"
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      resources {
        cpu    = 40
        memory = 150
      }

    }
  }
}