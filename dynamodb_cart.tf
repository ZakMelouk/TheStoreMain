###############################################
# DynamoDB Table for Cart Service
###############################################

resource "aws_dynamodb_table" "cart" {
  name           = "cart-items"
  billing_mode   = "PAY_PER_REQUEST"  # No need for capacity planning
  hash_key       = "user_id"
  range_key      = "item_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "item_id"
    type = "S"
  }

  # Encryption and replication configuration
  server_side_encryption {
    enabled = true
  }

  # Tagging for monitoring and traceability
  tags = {
    Name        = "cart-dynamodb"
    Environment = var.environment
    Project     = "the-store"
  }
}
