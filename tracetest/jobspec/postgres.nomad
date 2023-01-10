job "postgres" {

  datacenters = ["dc1"]
  type        = "service"

  group "postgres" {
    restart {
      attempts = 10
      interval = "5m"
      delay    = "10s"
      mode     = "delay"
    }

    network {
      
      port "db" {
        static = 5433
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "docker.io/bitnami/postgresql:14.6.0-debian-11-r13"
        image_pull_timeout = "25m"
        ports = ["db"]
      }
      env {
          BITNAMI_DEBUG = "false"
          POSTGRESQL_PORT_NUMBER = "${NOMAD_PORT_db}"
          POSTGRESQL_VOLUME_DIR = "/bitnami/postgresql"
          PGDATA = "/bitnami/postgresql/data"
          POSTGRES_USER = "tracetest"
          POSTGRES_POSTGRES_PASSWORD = "gQmBTFiUBv"
          POSTGRES_PASSWORD = "not-secure-database-password"
          POSTGRES_DB = "tracetest"
          POSTGRESQL_ENABLE_LDAP = "no"
          POSTGRESQL_LOG_HOSTNAME = "false"
          POSTGRESQL_LOG_CONNECTIONS = "false"
          POSTGRESQL_LOG_DISCONNECTIONS = "false"
          POSTGRESQL_PGAUDIT_LOG_CATALOG = "off"
          POSTGRESQL_CLIENT_MIN_MESSAGES = "error"
          POSTGRESQL_SHARED_PRELOAD_LIBRARIES = "pgaudit"
      }

      resources {
        cpu    = 50
        memory = 250
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      service {
        name = "postgres-tracetest"
        port = "db"

        check {
          interval = "10s"
          timeout  = "5s"
          type     = "script"
          command  = "pg_isready"
          args     = [
            "-d", "dbname=tracetest",
            "-h", "${NOMAD_IP_db}",
            "-p", "${NOMAD_PORT_db}",
            "-U", "tracetest"
          ]
        }
      }

    }
  }
}