data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ecs_task_policy" {
  name = "ecs-task-policy-new"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage"
        ],
        Resource = aws_sqs_queue.messages.arn
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ],
        Resource = aws_sqs_queue.messages.arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.data_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_attach_main" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_iam_policy" "ecs_task_ssm_policy" {
  name = "ssm-access-to-token-new"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory"
        ],
        Resource = "arn:aws:ssm:us-east-2:${data.aws_caller_identity.current.account_id}:parameter/myapp/auth/token"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_attach_ssm" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_ssm_policy.arn
}
