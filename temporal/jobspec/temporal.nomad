job "temporal" {
  datacenters = ["dc1"]

  group "svc" {
    count = 1

    network {
      mode = "bridge"

      port  "temporal-app"{
        to = 7233
      }

      port  "temporal-web"{
        to = 8088
      }
    }

    service {
      name = "temporal-app"
      tags = [
        "traefik.tcp.routers.temporal-app.rule=HostSNI(`*`)",
        "traefik.tcp.routers.temporal-app.entrypoints=grpc",
        "traefik.enable=true",
      ]        

      port = "temporal-app"
    }

    service {
      name = "temporal-web"
      tags = [
        "traefik.http.routers.temporal-web.rule=Host(`temporal-web.localhost`)",
        "traefik.http.routers.temporal-web.entrypoints=web",
        "traefik.http.routers.temporal-web.tls=false",
        "traefik.enable=true",
      ]

      port = "temporal-web"
    }

    task "temporal-app" {
      driver = "docker"

      env {
        DB = "mysql"
        DB_PORT = 3306
        MYSQL_USER = "root"
        MYSQL_PWD = "password"
        DYNAMIC_CONFIG_FILE_PATH = "config/dynamicconfig/development.yaml"
        BIND_ON_IP = "0.0.0.0"
        TEMPORAL_BROADCAST_ADDRESS = "127.0.0.1"
      }

      config {
        image = "temporalio/auto-setup:1.15.1"
        force_pull = true

        ports = ["temporal-app"]
      }

      resources {
        memory = 250
      }

      template {
        data = <<EOF
{{ range service "mysql-server" }}
MYSQL_SEEDS = "{{ .Address }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      template {
        data   = <<EOF
frontend.keepAliveMaxConnectionAge:
- value: 5m
frontend.keepAliveMaxConnectionAgeGrace:
- value: 70s
frontend.enableClientVersionCheck:
- value: true
  constraints: {}
history.persistenceMaxQPS:
- value: 3000
  constraints: {}
frontend.persistenceMaxQPS:
- value: 3000
  constraints: {}
frontend.historyMgrNumConns:
- value: 10
  constraints: {}
frontend.throttledLogRPS:
- value: 20
  constraints: {}
history.historyMgrNumConns:
- value: 50
  constraints: {}
history.defaultActivityRetryPolicy:
- value:
    InitialIntervalInSeconds: 1
    MaximumIntervalCoefficient: 100.0
    BackoffCoefficient: 2.0
    MaximumAttempts: 0
history.defaultWorkflowRetryPolicy:
- value:
    InitialIntervalInSeconds: 1
    MaximumIntervalCoefficient: 100.0
    BackoffCoefficient: 2.0
    MaximumAttempts: 0
system.advancedVisibilityWritingMode:
- value: "off"
  constraints: {}
EOF
        destination = "config/dynamicconfig/development.yaml"
      }
      
    }

    task "temporal-web" {
      driver = "docker"

      env {
        TEMPORAL_GRPC_ENDPOINT = "127.0.0.1:7233"
        TEMPORAL_PERMIT_WRITE_API = true
      }

      config {
        image = "temporalio/web:1.14.0"
        force_pull = true

        ports = ["temporal-web"]
      }

      resources {
        memory = 250
      }

    }
  }
  
}