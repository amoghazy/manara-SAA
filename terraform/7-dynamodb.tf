
resource "aws_dynamodb_table" "users_table" {
  name         = "users-sharp-images"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"
  attribute {
    name = "email"
    type = "S"
  }
}
