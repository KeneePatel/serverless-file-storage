resource "aws_dynamodb_table" "file_metadata" {
  name           = "${var.project_name}-files"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"
  range_key      = "fileId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "fileId"
    type = "S"
  }

  attribute {
    name = "fileName"
    type = "S"
  }

  global_secondary_index {
    name            = "FileNameIndex"
    hash_key        = "fileName"
    projection_type = "ALL"
  }
}
