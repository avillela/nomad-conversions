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
        interval = "10s"
        timeout  = "5s"
        type     = "script"
        task     = "redis"
        command  = "redis-cli"
        args     = [
          "-h", "${NOMAD_IP_db}",
          "-p", "${NOMAD_PORT_db}",
          "PING"
        ]
      }
    }

 
    task "redis" {
      driver = "docker"
 
      config {
        image = "redis:alpine"
        image_pull_timeout = "25m"
        ports = ["db"]
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      resources {
        cpu    = 55
        memory = 150
      }

    }
  }
}