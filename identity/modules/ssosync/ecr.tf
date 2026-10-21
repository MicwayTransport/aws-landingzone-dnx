resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  ecr_repository_prefix = var.ecr_prefix
  upstream_registry_url = var.ecr_upstream_registry_url
}

resource "aws_ecr_registry_policy" "pull_through" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = "*", //FIXME
      Action = [
        "ecr:CreateRepository",
        "ecr:BatchImportUpstreamImage"
      ],
      Resource = aws_ecr_repository.ssosync.arn
    }]
  })
}

resource "aws_ecr_repository" "ssosync" {
  name = "${aws_ecr_pull_through_cache_rule.ecr_public.ecr_repository_prefix}/${var.lambda_image}"
}
