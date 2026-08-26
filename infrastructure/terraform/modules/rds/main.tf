variable "name"               { type = string }
variable "vpc_id"             { type = string }
variable "subnet_ids"         { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "db_name"            { type = string }
variable "db_username"        { type = string }
variable "db_password"        { type = string }
variable "instance_class"     { type = string }

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.name}-db-subnet-group" }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier     = "${var.name}-db"
  engine                 = "aurora-postgresql"
  engine_version         = "16.6"
  database_name          = var.db_name
  master_username        = var.db_username
  master_password        = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  storage_encrypted      = true
  skip_final_snapshot    = true

  tags = { Name = "${var.name}-db-cluster" }
}

resource "aws_rds_cluster_instance" "this" {
  count                = 1
  identifier           = "${var.name}-db-${count.index}"
  cluster_identifier   = aws_rds_cluster.this.id
  instance_class       = var.instance_class
  engine               = aws_rds_cluster.this.engine
  engine_version       = aws_rds_cluster.this.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.this.name

  tags = { Name = "${var.name}-db-instance" }
}

output "endpoint" { value = aws_rds_cluster.this.endpoint }
output "port"     { value = aws_rds_cluster.this.port }
