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
        image_pull_timeout = "25m"
        ports = ["http"]
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      // artifact {
      //   source      = "github.com/open-telemetry/opentelemetry-demo/src/grafana/provisioning"
      //   destination = "/etc/grafana/provisioning"
      // }

      // artifact {
      //   source      = "github.com/open-telemetry/opentelemetry-demo/src/grafana/grafana.ini"
      //   destination = "/etc/grafana/grafana.ini"
      // }

      env {
        GF_AUTH_ANONYMOUS_ENABLED  = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Editor"
        GF_SERVER_HTTP_PORT        = "${NOMAD_PORT_http}"

        // GF_PATHS_DATA = "/var/lib/grafana/"
        // GF_PATHS_LOGS = "/var/log/grafana"
        // GF_PATHS_PLUGINS = "/var/lib/grafana/plugins"
        GF_LOG_LEVEL = "DEBUG"
        GF_LOG_MODE = "console"
        // GF_PATHS_PROVISIONING = "/etc/grafana/provisioning"
      }

      template {
        data = <<EOH
[analytics]
check_for_updates = true
[auth]
disable_login_form = true
[auth.anonymous]
enabled = true
org_name = Main Org.
org_role = Admin
[grafana_net]
url = https://grafana.net
[log]
mode = console
[paths]
data = /var/lib/grafana/
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins
provisioning = /etc/grafana/provisioning
[server]
root_url = http://frontendproxy.localhost/grafana
serve_from_sub_path = true
EOH
        destination = "/etc/grafana/grafana.ini"
      }

      template {
        data = <<EOH
apiVersion: 1
datasources:
- editable: true
  isDefault: true
  name: Prometheus
  type: prometheus
  uid: webstore-metrics
  url: http://{{ range service "prometheus" }}{{ .Address }}:{{ .Port }}{{ end }}
- editable: true
  isDefault: false
  name: Jaeger
  type: jaeger
  uid: webstore-traces
  url: http://{{ range service "jaeger-collector" }}{{ .Address }}:{{ .Port }}{{ end }}
EOH
        destination = "/etc/grafana/provisioning/datasources/datasources.yaml"
      }

      template {
        data = <<EOH
apiVersion: 1
providers:
- disableDeletion: false
  editable: true
  folder: ""
  name: default
  options:
    path: /var/lib/grafana/dashboards/default
  orgId: 1
  type: file
EOH
        destination = "/etc/grafana/provisioning/dashboards/dashboardproviders.yaml"
      }

      resources {
        cpu    = 60
        memory = 100
      }
    }
  }
}