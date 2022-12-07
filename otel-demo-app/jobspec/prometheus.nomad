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
      name = "prometheus"
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
        image_pull_timeout = "25m"
        args = [
          "--storage.tsdb.retention.time=15d",
          "--config.file=/etc/config/prometheus.yml",
          "--storage.tsdb.path=/data",
          "--web.console.libraries=/etc/prometheus/console_libraries",
          "--web.console.templates=/etc/prometheus/consoles",
          "--web.enable-lifecycle"
          // "--web.console.templates=/etc/prometheus/consoles",
          // "--web.console.libraries=/etc/prometheus/console_libraries",
          // "--storage.tsdb.retention.time=1h",
          // "--config.file=/etc/config/prometheus.yml",
          // "--storage.tsdb.path=/prometheus",
          // "--web.enable-lifecycle",
          // "--web.route-prefix=/"
        ]

        ports = ["containerport"]
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      // artifact {
      //   source      = "github.com/lightstep/opentelemetry-demo/src/prometheus/prometheus-config.yaml"
      //   destination = "/etc/prometheus/prometheus-config.yaml"
      // }

      template {
        data = <<EOH
{}
EOH
        destination = "/etc/config/alerting_rules.yml"
      }

      template {
        data = <<EOH
{}
EOH
        destination = "/etc/config/alerts"
      }


      template {
        data = <<EOH
global:
  evaluation_interval: 30s
  scrape_interval: 5s
  scrape_timeout: 3s
rule_files:
- /etc/config/recording_rules.yml
- /etc/config/alerting_rules.yml
- /etc/config/rules
- /etc/config/alerts
scrape_configs:
- job_name: opentelemetry-community-demo
  nomad_sd_configs:
    - server: 'http://{{ env "attr.unique.network.ip-address" }}:4646'
  relabel_configs:
    - source_labels: ['__meta_nomad_tags']
      regex: '(.*),metrics,(.*)'
      action: keep
    - source_labels: [__meta_nomad_service]
      target_label: job
EOH
        destination = "/etc/config/prometheus.yml"
      }

      template {
        data = <<EOH
{}
EOH
        destination = "/etc/config/recording_rules.yml"
      }

      template {
        data = <<EOH
{}
EOH
        destination = "/etc/config/rules"
      }

      resources {
        cpu    = 60
        memory = 100
      }

    }
  }
}