job "k0s" {
  group "k0s" {
    task "k0s" {
      driver = "docker"
      config {
        image      = "docker.io/k0sproject/k0s:latest"
        privileged = true
      }

      resources {
        memory = 2048
      }
    }
  }
}