job "prometheus" {
  type        = "service"
  datacenters = ["dc1"]

  group "prometheus" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 9090
      }
    }

    service {
      provider = "nomad"
      tags = [
        "traefik.http.routers.prometheus.rule=Host(`prometheus.localhost`)",
        "traefik.http.routers.prometheus.entrypoints=web",
        "traefik.http.routers.prometheus.tls=false",
        "traefik.enable=true",
      ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "prometheus" {
      driver = "docker"
 
      config {
        image = "quay.io/prometheus/prometheus:v2.34.0"
        args = [
          "--web.console.templates=/etc/prometheus/consoles",
          "--web.console.libraries=/etc/prometheus/console_libraries",
          "--storage.tsdb.retention.time=1h",
          "--config.file=/etc/prometheus/prometheus-config.yaml",
          "--storage.tsdb.path=/prometheus",
          "--web.enable-lifecycle",
          "--web.route-prefix=/"
        ]

        ports = ["containerport"]
      }
      artifact {
        source      = "github.com/lightstep/opentelemetry-demo/src/prometheus/prometheus-config.yaml"
        destination = "/etc/prometheus/prometheus-config.yaml"
      }

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}