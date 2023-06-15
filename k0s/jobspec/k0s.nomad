# This is a translation of the k0s Docker Compose file here: https://docs.k0sproject.io/v1.23.6+k0s.2/k0s-in-docker/#use-docker-compose-alternative
# For a complete config file, see: https://docs.k0sproject.io/v1.23.6+k0s.2/configuration/
# You will need to uncomment line 25 and replace the config file with your own.
job "k0s" {
  group "k0s" {
    network {
      port "k0s" {
        static = 6443
      }
    }

    volume "k0s" {
      type   = "host"
      source = "k0s"
    }

    task "k0s" {
      driver = "docker"

      config {
        image   = "docker.io/k0sproject/k0s:latest"
        command = "k0s"
        args = [
          "controller",
          // "--config=${NOMAD_TASK_DIR}/config.yaml",
          "--enable-worker",
        ]

        privileged = true
        hostname   = "k0s"
        ports      = ["k0s"]

        mount {
          type   = "tmpfs"
          target = "/run"

          tmpfs_options {
            size = 50000000 # size in bytes
          }
        }

        mount {
          type   = "tmpfs"
          target = "/var/run"

          tmpfs_options {
            size = 50000000 # size in bytes
          }
        }
      }

      template {
        data        = <<EOF
apiVersion: k0s.k0sproject.io/v1beta1
kind: ClusterConfig
metadata:
  name: k0s
# Any additional configuration goes here ...
EOF
        destination = "${NOMAD_TASK_DIR}/config.yaml"
      }

      volume_mount {
        volume      = "k0s"
        destination = "/var/lib/k0s"
      }

      resources {
        memory = 2048
      }
    }
  }
}