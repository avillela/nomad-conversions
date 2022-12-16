job "tracetest" {

  datacenters = ["dc1"]

  group "svc" {
    count = 1


    network {

      port "tracetest-app" {
        to = 8080
      }

    }

    service {
      tags = [
        "traefik.http.routers.tracetest.rule=Host(`tracetest.localhost`)",
        "traefik.http.routers.tracetest.entrypoints=web",
        "traefik.http.routers.tracetest.tls=false",
        "traefik.enable=true",
      ]

      port = "tracetest-app"

    }

    task "svc" {
      driver = "docker"

      config {
        image = "kubeshop/tracetest:v0.4.3"

        args = [
          "-config", "/local/config.yaml"
        ]

        ports = [
          "tracetest-app",
        ]
      }

      env {
        VERSION = "v0.2.3"
      }

      resources {
        cpu    = 100
        memory = 512
      }

      template {
        data   = <<EOF

    maxWaitTimeForTrace: 100s
    googleAnalytics:
      enabled: false
      measurementId: "G-WP4XXN1FYN"
      secretKey: "QHaq8ZCHTzGzdcRxJ-NIbw"
    postgresConnString: "host=postgres.localhost user=tracetest password=not-secure-database-password  port=5432 sslmode=disable"
    
    jaegerConnectionConfig:
      endpoint: jaeger-grpc.localhost:7233
      tls:
        insecure: true
EOF
        destination = "/local/config.yaml"
      }
    }
  }
}