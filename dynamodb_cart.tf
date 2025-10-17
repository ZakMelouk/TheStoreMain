###############################################
# DynamoDB Table for Cart Service
###############################################

resource "aws_dynamodb_table" "cart" {
  name           = "cart-items"
  billing_mode   = "PAY_PER_REQUEST"  # Pas besoin de capacity planning
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

  # Configuration du chiffrement et de la réplication
  server_side_encryption {
    enabled = true
  }

  # Tagging pour suivi et traçabilité
  tags = {
    Name        = "cart-dynamodb"
    Environment = var.environment
    Project     = "the-store"
  }
}
