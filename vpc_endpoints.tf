###############################################
# VPC Endpoint for DynamoDB (Private Access)
###############################################

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  # Associe l’endpoint aux tables de routage privées
  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name        = "dynamodb-vpc-endpoint"
    Environment = var.environment
    Project     = "the-store"
  }
}
