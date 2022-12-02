# https://traefik.io/blog/traefik-proxy-fully-integrates-with-hashicorp-nomad/

job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port  "http"{
         static = 80
      }
      port  "admin"{
         static = 8181
      }

      port "api" {
        static = 8080
      }

      port "metrics" {
        static = 8082
      }

      port "grpc" {
        static = 7233
      }

    }

    service {
      name = "traefik-dashboard"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.dashboard.rule=Host(`traefik.localhost`)",
        "traefik.http.routers.dashboard.service=api@internal",
        "traefik.http.routers.dashboard.entrypoints=web",
      ]

      port = "http"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

    service {
      name = "traefik-grpc"
      provider = "nomad"
      port = "grpc"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

    task "server" {
      driver = "docker"
      config {
        image = "traefik:v2.8.0-rc1"
        ports = ["admin", "http", "api", "metrics", "grpc"]
        args = [
          "--api.dashboard=true",
          "--api.insecure=true", ### For Test only, please do not use that in production
          "--log.level=DEBUG",
          "--entrypoints.web.address=:${NOMAD_PORT_http}",
          "--entrypoints.traefik.address=:${NOMAD_PORT_admin}",
          "--entrypoints.metrics.address=:${NOMAD_PORT_metrics}",
          "--entrypoints.grpc.address=:${NOMAD_PORT_grpc}",
          "--providers.nomad=true",
          "--providers.nomad.endpoint.address=http://10.9.99.10:4646" ### IP to your nomad server 
        ]
      }

      resources {
        cpu    = 75
        memory = 100
      }

    }
  }
}
