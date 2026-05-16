data "aws_s3_bucket" "main" {
  bucket = var.my_team1_s3_bucket_name
}

# Optional existing bucket for storing LLM logs
# If you want to use an existing bucket, set llm_logs_bucket_name in terraform.tfvars.
data "aws_s3_bucket" "llm_logs" {
  count  = var.llm_logs_bucket_name != "" ? 1 : 0
  bucket = var.llm_logs_bucket_name
}
