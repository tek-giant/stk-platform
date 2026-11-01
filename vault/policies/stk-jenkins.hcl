# Jenkins may read exactly one secret and nothing else.
path "stk/data/ci/demo" {
  capabilities = ["read"]
}
