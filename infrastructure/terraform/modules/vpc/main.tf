variable "name"       { type = string }
variable "cidr"       { type = string }
variable "azs"        { type = list(string) }
variable "project_name" { type = string }

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = var.name }
}

# ── Public Subnets ──────────────────────────────────────────

resource "aws_subnet" "public" {
  for_each = { for idx, az in var.azs : az => idx }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr, 8, each.value)
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = { Name = "${var.name}-public-${each.key}" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ── Private Subnets ─────────────────────────────────────────

resource "aws_subnet" "private" {
  for_each = { for idx, az in var.azs : az => idx }

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr, 8, each.value + 100)
  availability_zone = each.key

  tags = { Name = "${var.name}-private-${each.key}" }
}

resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = { Name = "${var.name}-nat-eip-${each.key}" }
}

resource "aws_nat_gateway" "this" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = { Name = "${var.name}-nat-${each.key}" }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = { for idx, az in var.azs : az => idx }

  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-private-rt-${each.key}" }
}

resource "aws_route" "private_nat" {
  for_each               = aws_nat_gateway.this
  route_table_id         = aws_route_table.private[keys(aws_subnet.public)[index(keys(aws_nat_gateway.this), each.key)]].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = each.value.id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# ── Outputs ─────────────────────────────────────────────────

output "vpc_id"            { value = aws_vpc.this.id }
output "public_subnets"    { value = [for s in aws_subnet.public : s.id] }
output "private_subnets"   { value = [for s in aws_subnet.private : s.id] }
