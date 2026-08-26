variable "name"               { type = string }
variable "subnet_ids"         { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "node_type"          { type = string }

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-redis"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.name}-redis"
  description          = "Redis cluster for ${var.name}"

  node_type            = var.node_type
  num_cache_clusters   = 1
  engine_version       = "7.1"
  port                 = 6379

  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = var.security_group_ids

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  automatic_failover_enabled = false
  multi_az_enabled           = false

  snapshot_retention_limit = 0

  tags = { Name = "${var.name}-redis" }
}

output "endpoint" { value = aws_elasticache_replication_group.this.primary_endpoint_address }
output "port"     { value = aws_elasticache_replication_group.this.port }
