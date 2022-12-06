job "grafana" {
  region = "global"

  datacenters = ["dc1"]
  namespace   = "default"
  
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "grafana" {
    count = 1  
    restart {
      attempts = 10
      interval = "5m"
      delay = "10s"
      mode = "delay"
    }
    network {
      port "http" {
        to = "3000"
      }
    }

    service {
      name = "grafana"
      tags = [
        "traefik.http.routers.grafana.rule=Host(`grafana.localhost`)",
        "traefik.http.routers.grafana.entrypoints=web",
        "traefik.http.routers.grafana.tls=false",
        "traefik.enable=true",
      ]

      port = "http"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }


    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:9.1.0"

        ports = ["http"]
      }
      artifact {
        source      = "github.com/open-telemetry/opentelemetry-demo/src/grafana"
        destination = "/etc/grafana"
      }

      // artifact {
      //   source      = "github.com/open-telemetry/opentelemetry-demo/src/grafana/grafana.ini"
      //   destination = "/etc/grafana/grafana.ini"
      // }

      env {
        GF_PATHS_DATA = "/var/lib/grafana/"
        GF_PATHS_LOGS = "/var/log/grafana"
        GF_PATHS_PLUGINS = "/var/lib/grafana/plugins"
        GF_LOG_LEVEL = "DEBUG"
        GF_LOG_MODE = "console"
        GF_SERVER_HTTP_PORT = "${NOMAD_PORT_http}"
        GF_PATHS_PROVISIONING = "/etc/grafana/provisioning"
      }


      resources {
        cpu    = 45 # 500 MHz
        memory = 100 # 256MB
      }
    }
  }
}