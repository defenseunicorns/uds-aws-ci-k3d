terraform {
  backend "s3" {
    region         = "us-west-2"
    bucket         = "uds-aws-ci-commercial-us-west-2-657a-tfstate"
    dynamodb_table = "uds-aws-ci-commercial-us-west-2-657a-tfstate-lock"
  }
}
