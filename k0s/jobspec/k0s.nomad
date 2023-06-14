job "k0s" {
  datacenters = ["dc1"]
  type        = "service"

  group "k0s" {
    count = 1

    // volume "k0s" {
    //   type      = "host"
    //   read_only = false
    //   source    = "k0s"
    // }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "k0s" {
      driver = "docker"

      // volume_mount {
      //   volume      = "k0s"
      //   destination = "/var/lib/k0s"
      //   read_only   = false
      // }


      config {
        image = "docker.io/k0sproject/k0s:latest"
        image_pull_timeout = "15m"
        // command = "k0s controller"
        privileged = true
        // args = [
            // "--config=local/config/config.yaml",
            // "--enable-worker"
        // ]

        ports = ["k0s"]

        mount {
          type = "tmpfs"
          target = "/var/lib/k0s"
          readonly = false
          tmpfs_options {
            size = 300000000 # size in bytes
          }
        }

        mount {
          type = "tmpfs"
          target = "/run"
          readonly = false
          tmpfs_options {
            size = 50000000 # size in bytes
          }
        }

        mount {
          type = "tmpfs"
          target = "/var/run"
          readonly = false
          tmpfs_options {
            size = 50000000 # size in bytes
          }
        }
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      service {
        name = "k0s"
        port = "k0s"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      template {
        data = <<EOF
apiVersion: k0s.k0sproject.io/v1beta1
kind: ClusterConfig
metadata:
  name: k0s
EOF

        change_mode   = "restart"
        destination = "local/config/config.yaml"
        // destination = "local/env"
        // env         = true
      }

    }
    network {
      port "k0s" {
        static = 6443
      }
    }
  }
}

