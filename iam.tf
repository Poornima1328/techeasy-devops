resource "aws_iam_role" "readonly_s3" {
  name = "ReadOnlyS3Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" },
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "readonly_attach" {
  role       = aws_iam_role.readonly_s3.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role" "upload_s3" {
  name = "UploadOnlyS3Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = { Service = "ec2.amazonaws.com" },
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_policy" "upload_policy" {
  name = "UploadOnlyPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:PutObject", "s3:CreateBucket"],
        Resource = ["arn:aws:s3:::${var.bucket_name}", "arn:aws:s3:::${var.bucket_name}/*"]
      },
      {
        Effect = "Deny",
        Action = ["s3:GetObject", "s3:ListBucket"],
        Resource = ["arn:aws:s3:::${var.bucket_name}", "arn:aws:s3:::${var.bucket_name}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "upload_attach" {
  role       = aws_iam_role.upload_s3.name
  policy_arn = aws_iam_policy.upload_policy.arn
}

resource "aws_iam_instance_profile" "upload_profile" {
  name = "UploadInstanceProfile"
  role = aws_iam_role.upload_s3.name
}
