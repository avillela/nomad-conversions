// Base image obtained from: https://github.com/hashicorp/nomad-autoscaler-demos/blob/main/vagrant/horizontal-app-scaling/jobs/prometheus.nomad
// Modifications made based on: https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-demo/examples/default/rendered/prometheus
job "prometheus" {
  region = "global"

  datacenters = ["dc1"]
  namespace   = "default"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }


  group "prometheus" {
    count = 1

    network {
      port "prometheus_ui" {}
    }

    task "prometheus" {
      driver = "docker"

      config {
        // image = "quay.io/prometheus/prometheus:v2.34.0"
        image = "prom/prometheus:v2.38.0"
        ports = ["prometheus_ui"]

        network_mode = "host"

        args = [
          "--config.file=/etc/config/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.listen-address=0.0.0.0:${NOMAD_PORT_prometheus_ui}",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.enable-lifecycle"
        ]

        volumes = [
          "local/config:/etc/config",
        ]
      }

      template {
        data = <<EOH
---
global:
  evaluation_interval: 30s
  scrape_interval: 5s
scrape_configs:
- job_name: otel
  static_configs:
  - targets:
    - '{{ range service "otelcol-prometheus" }}{{ .Address }}:{{ .Port }}{{ end }}'
- job_name: otel-collector
  static_configs:
  - targets:
    - '{{ range service "otelcol-metrics" }}{{ .Address }}:{{ .Port }}{{ end }}'

EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/prometheus.yml"
      }

      template {
        data = <<EOH
{}
EOH
        destination = "local/config/recording_rules.yml"
      }

      template {
        data = <<EOH
{}
EOH
        destination = "local/config/rules"
      }

      template {
        data = <<EOH
{}
EOH
        destination = "local/config/alerting_rules.yml"
      }

      template {
        data = <<EOH
{}
EOH
        destination = "local/config/alerts"
      }

      resources {
        cpu    = 100
        memory = 256
      }

      service {
        name     = "prometheus"
        port     = "prometheus_ui"
        tags = [
          "traefik.http.routers.prometheus.rule=Host(`prometheus.localhost`)",
          "traefik.http.routers.prometheus.entrypoints=web",
          "traefik.http.routers.prometheus.tls=false",
          "traefik.enable=true",
        ]

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}