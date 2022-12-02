job "redis" {
  type        = "service"
  datacenters = ["dc1"]

  group "redis" {
    count = 1

    network {
      mode = "host"

      port "db" {
        static = 6379
      }
    }

    service {
      name = "redis-service"
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
        cpu    = 55
        memory = 150
      }

    }
  }
}