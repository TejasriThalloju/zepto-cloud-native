resource "aws_iam_policy" "quickcart_secrets_read" {
  name        = "QuickCartSecretsReadPolicy"
  description = "Allows QuickCart EKS pods to read Secrets Manager secrets"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadQuickCartDatabaseSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role" "quickcart_pod_secrets_role" {
  name = "QuickCartPodSecretsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "quickcart_secrets_attachment" {
  role       = aws_iam_role.quickcart_pod_secrets_role.name
  policy_arn = aws_iam_policy.quickcart_secrets_read.arn
}