job "go-server" {

  datacenters = ["dc1"]

  group "svc" {
    count = 1


    network {

      port "app-port" {
        to = 9000
      }

    }

    service {
      tags = [
        "traefik.http.routers.go-server.rule=Host(`go-server.localhost`)",
        "traefik.http.routers.go-server.entrypoints=web",
        "traefik.http.routers.go-server.tls=false",
        "traefik.enable=true",
      ]

      port = "app-port"

    }

    task "svc" {
      driver = "docker"
      
      config {
        image = "ghcr.io/avillela/go-sample-server:1.0.0"
        force_pull = true
        image_pull_timeout = "20m"
        ports = [
          "app-port",
        ]
      }

      resources {
        cpu    = 100
        memory = 512
      }

    }
  }
}