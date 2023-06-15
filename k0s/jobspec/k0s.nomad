job "k0s" {
  group "k0s" {

    network {
      port "k0s" {
        static = 6443
      }
    }

    task "k0s" {
      driver = "docker"
      config {
        image      = "docker.io/k0sproject/k0s:latest"
        privileged = true

        ports = [
          "k0s"
        ]
      }

      service {
        port = "k0s"
      }
      
      resources {
        memory = 2048
      }
    }
  }
}