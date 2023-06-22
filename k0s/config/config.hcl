# Nomad config file if you want to run Nomad locally in dev mode
client {
  host_volume "k0s" {
    # If the directory doesn't already exist, run: mkdir -p ~/k0s
    path = "~/k0s"
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
