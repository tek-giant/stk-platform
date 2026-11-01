# Read-only access to the secrets under stk/. No write, no delete, nothing else.
path "stk/data/*" {
  capabilities = ["read"]
}

path "stk/metadata/*" {
  capabilities = ["list", "read"]
}
