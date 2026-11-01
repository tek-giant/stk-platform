ui            = true
disable_mlock = true
api_addr      = "http://127.0.0.1:8200"

storage "file" {
  path = "/vault/file"
}

# Laptop lab only: plain HTTP, published on 127.0.0.1 and nowhere else. A real deployment needs TLS.
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}
