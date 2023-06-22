client {
  host_volume "k0s" {
    # Adjust to your environment.
    path = "/Users/laoqui/k0s"
  }
}

plugin "docker" {
  config {
    allow_privileged = true

    volumes {
      enabled = true
    }
  }
}