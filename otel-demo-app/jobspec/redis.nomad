job "redis" {
  type        = "service"
  datacenters = ["dc1"]

  group "redis" {
    count = 1

    network {
      mode = "host"

      port "db" {
        to = 6379
      }
    }

    service {
      provider = "nomad"
      tags = [
        "traefik.http.routers.redis.rule=Host(`redis.localhost`)",
        "traefik.http.routers.redis.entrypoints=web",
        "traefik.http.routers.redis.tls=false",
        "traefik.enable=true",
      ]

      port = "db"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "redis" {
      driver = "docker"
 
      config {
        image = "redis:alpine"

        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}