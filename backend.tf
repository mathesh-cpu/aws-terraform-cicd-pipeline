terraform {
  backend "s3" {
    bucket = "enterprise-tf-state-matheshwaran" 
    key    = "prod/terraform.tfstate"
    region = "ap-south-1"
  }
}