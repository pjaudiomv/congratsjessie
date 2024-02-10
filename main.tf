locals {
  function_url_id = "${aws_lambda_function_url.this.url_id}.lambda-url.us-east-1.on.aws"
  tld             = "congratsjessie.com"
}

######################
#  Lambda
######################

data "archive_file" "congratsjessie_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/congratsjessie.zip"
}

resource "aws_cloudwatch_log_group" "congratsjessie" {
  name              = "/aws/lambda/${aws_lambda_function.congratsjessie.id}"
  retention_in_days = 7
}

resource "aws_lambda_function" "congratsjessie" {
  function_name                  = "congratsjessie"
  filename                       = data.archive_file.congratsjessie_lambda.output_path
  handler                        = "congratsjessie.handler"
  role                           = aws_iam_role.congratsjessie.arn
  reserved_concurrent_executions = 10
  source_code_hash               = data.archive_file.congratsjessie_lambda.output_base64sha256
  runtime                        = "python3.10"
  timeout                        = 1

  environment {
    variables = {
      JFT_VAR = ""
    }
  }

  tags = {
    Name = "congratsjessie"
  }
}

resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.congratsjessie.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_headers     = []
    allow_methods = [
      "GET",
    ]
    allow_origins = [
      "*",
    ]
    expose_headers = []
    max_age        = 0
  }
}

data "aws_iam_policy_document" "congratsjessie_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "congratsjessie" {
  name               = "congratsjessie"
  description        = "For congratsjessie Lambda"
  assume_role_policy = data.aws_iam_policy_document.congratsjessie_assume_role.json
  tags = {
    Name = "jft"
  }
}

resource "aws_iam_policy" "congratsjessie_policy" {
  name   = "congratsjessie-lambda-role"
  policy = data.aws_iam_policy_document.congratsjessie_policy.json
}

resource "aws_iam_role_policy_attachment" "congratsjessie_policy_attachment" {
  role       = aws_iam_role.congratsjessie.name
  policy_arn = aws_iam_policy.congratsjessie_policy.arn
}

data "aws_iam_policy_document" "congratsjessie_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.congratsjessie.arn}:*"]
  }
}

resource "aws_cloudfront_distribution" "this" {
  aliases             = [local.tld, "www.${local.tld}"]
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  wait_for_deployment = true

  default_cache_behavior {
    target_origin_id       = local.function_url_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name         = local.function_url_id
    connection_attempts = 3
    connection_timeout  = 10
    origin_id           = local.function_url_id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.this.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_acm_certificate" "this" {
  domain_name       = local.tld
  validation_method = "DNS"
  subject_alternative_names = [
    "www.${local.tld}",
  ]
  tags = {
    "Name" = local.tld
  }
}

resource "namecheap_domain_records" "congratsjessie-com" {
  domain = "congratsjessie.com"

  record {
    address  = aws_cloudfront_distribution.this.domain_name
    hostname = "@"
    mx_pref  = 10
    ttl      = 1799
    type     = "CNAME"
  }
  record {
    address  = aws_cloudfront_distribution.this.domain_name
    hostname = "www"
    mx_pref  = 10
    ttl      = 1799
    type     = "CNAME"
  }

  dynamic "record" {
    for_each = toset(aws_acm_certificate.this.domain_validation_options)
    content {
      address  = record.value.resource_record_value
      hostname = replace(record.value.resource_record_name, ".congratsjessie.com.", "")
      ttl      = 1799
      type     = "CNAME"
    }
  }
}

output "function_url" {
  value = aws_lambda_function_url.this.function_url
}
