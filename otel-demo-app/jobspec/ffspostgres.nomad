job "ffspostgres" {

  datacenters = ["dc1"]
  type        = "service"

  group "ffspostgres" {
    restart {
      attempts = 10
      interval = "5m"
      delay    = "10s"
      mode     = "delay"
    }

    network {
      
      port "db" {
        to = 5432
      }
    }

    task "ffspostgres" {
      driver = "docker"

      config {
        image = "postgres:14"
        ports = ["db"]
      }
      env {
        POSTGRES_DB = "ffs"
        POSTGRES_PASSWORD = "ffs"
        POSTGRES_USER = "ffs"
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_SERVICE_NAME = "ffspostgres"
      }

      // resources {
      //   cpu    = 200
      //   memory = 512
      // }

      service {
        name = "ffpostgres-service"
        // provider = "nomad"
        // tags = [
        //   "traefik.tcp.routers.ffspostgres.rule=HostSNI(`*`)",
        //   "traefik.tcp.routers.ffspostgres.entrypoints=grpc",
        //   "traefik.enable=true",
        // ]
        port = "db"
      }

    }
  }
}