terraform {
  backend "s3" {
    bucket         = "aws-backend-bucket-2804"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "app-state"
  }
}
