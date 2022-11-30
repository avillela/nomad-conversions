job "otel-collector" {
  region = "global"

  datacenters = ["dc1"]
  namespace   = "default"

  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "otel-collector" {
    count = 1
    network {
      mode = "host"
      port "healthcheck" {
        to = 13133
      }
      port "jaeger-grpc" {
        to = 14250
      }
      port "jaeger-thrift-http" {
        to = 14268
      }
      port "metrics" {
        to = 8888
      }
      port "otlp" {
        to = 4317
      }
      port "otlphttp" {
        to = 4318
      }
      port "zipkin" {
        to = 9411
      }
      port "zpages" {
        to = 55679
      }
    }

    
    task "otel-collector" {
      driver = "docker"

      config {
        image = "otel/opentelemetry-collector-contrib:0.61.0"

        entrypoint = [
          "/otelcol-contrib",
          "--config=local/config/otel-collector-config.yaml",
        ]
        ports = [
  "otlphttp",
  "zipkin",
  "zpages",
  "healthcheck",
  "jaeger-grpc",
  "jaeger-thrift-http",
  "metrics",
  "otlp"
]

        

      }

      env {
        HOST_DEV = "/hostfs/dev"
        HOST_ETC = "/hostfs/etc"
        HOST_PROC = "/hostfs/proc"
        HOST_RUN = "/hostfs/run"
        HOST_SYS = "/hostfs/sys"
        HOST_VAR = "/hostfs/var"
    }

      template {
        data = <<EOH
receivers:
  otlp:
    protocols:
      grpc:
      http:
        endpoint: "0.0.0.0:4318"

processors:
  batch:
    timeout: 10s
  memory_limiter:
    # 75% of maximum memory up to 4G
    limit_mib: 1536
    # 25% of limit up to 2G
    spike_limit_mib: 512
    check_interval: 5s

exporters:
  logging:
    logLevel: debug

  otlp/ls:
    endpoint: ingest.lightstep.com:443
    headers: 
      "lightstep-access-token": "{{ with secret "kv/data/otel/o11y/lightstep" }}{{ .Data.data.api_key }}{{ end }}"

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [logging, otlp/ls]

EOH

        change_mode   = "restart"
        destination = "local/config/otel-collector-config.yaml"
      }

      

      resources {
        cpu    = 256
        memory = 512
      }
      service {
        provider = "nomad"
        name = "opentelemetry-collector"
        port = "metrics"
        tags = ["prometheus"]
      }
      service {
        provider = "nomad"
        name = "opentelemetry-collector"
        port = "zipkin"
        tags = ["zipkin"]
      }
      // service {
      //   name = "opentelemetry-collector"
      //   port = "healthcheck"
      //   tags = ["health"]
      //   check {
      //     type     = "http"
      //     path     = "/"
      //     interval = "15s"
      //     timeout  = "3s"
      //   }
      // }
      service {
        provider = "nomad"
        name = "opentelemetry-collector"
        port = "jaeger-grpc"
        tags = ["jaeger-grpc"]
      }
      service {
        provider = "nomad"
        name = "opentelemetry-collector"
        port = "jaeger-thrift-http"
        tags = ["jaeger-thrift-http"]
      }
      service {
        provider = "nomad"
        name = "opentelemetry-collector"
        port = "zpages"
        tags = ["zpages"]
      }

      
      service {
        provider = "nomad"
        tags = [
          "traefik.tcp.routers.otel-collector-grpc.rule=HostSNI(`*`)",
          "traefik.tcp.routers.otel-collector-grpc.entrypoints=grpc",
          "traefik.enable=true",
        ]        
        port = "otlp"
      }

      service {
        provider = "nomad"
        tags = [
          "traefik.http.routers.otel-collector-http.rule=Host(`otel-collector-http.localhost`)",
          "traefik.http.routers.otel-collector-http.entrypoints=web",
          "traefik.http.routers.otel-collector-http.tls=false",
          "traefik.enable=true",
        ]
        port = "otlphttp"
      }

    }
  }
}
