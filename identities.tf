#
# This role is used by RDS Start Export Task
#
resource "aws_iam_role" "rdsSnapshotExportTask" {
  count              = var.enabled ? 1 : 0
  name               = "${local.prefix}snapshot-export-task${local.postfix}"
  tags               = merge({ Name = "${local.prefix}snapshot-export-task${local.postfix}" }, var.tags)
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "export.rds.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
POLICY
}

#
# Allow RDS Start Export Task to write the snapshot on the S3 bucket
#
resource "aws_iam_role_policy" "rdsSnapshotExportToS3" {
  count  = var.enabled ? 1 : 0
  name   = "${local.prefix}rds-snapshot-export-to-s3${local.postfix}"
  role   = aws_iam_role.rdsSnapshotExportTask[0].id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ExportPolicy",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject*",
                "s3:ListBucket",
                "s3:GetObject*",
                "s3:DeleteObject*",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "${local.snapshots_bucket_arn}",
                "${local.snapshots_bucket_arn}/*"
            ]
        }
    ]
}
POLICY
}

#
# Lambda Permissions: Start Export Task
#
resource "aws_iam_policy" "rdsStartExportTaskLambda" {
  count  = var.enabled ? 1 : 0
  name   = "${local.prefix}rds-snapshot-exporter-lambda${local.postfix}"
  tags   = merge({ Name = "${local.prefix}rds-snapshot-exporter-lambda${local.postfix}" }, var.tags)
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "rds:StartExportTask",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "iam:PassRole",
            "Resource": ["${aws_iam_role.rdsSnapshotExportTask[0].arn}"],
            "Effect": "Allow"
        },
        {
            "Effect" : "Allow",
            "Action" : [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource" : [
                local.kms_key_arn
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": local.kms_key_arn,
            "Condition": {
                "Bool": { "kms:GrantIsForAWSResource": "true" }
            }
        }
    ]
}  
POLICY
}

#
# Lambda Permissions: Export Task Monitor
#
resource "aws_iam_policy" "rdsMonitorExportTaskLambda" {
  count  = var.enabled ? 1 : 0
  name   = "${local.prefix}rds-snapshot-exporter-monitor-lambda${local.postfix}"
  tags   = merge({ Name = "${local.prefix}rds-snapshot-exporter-monitor-lambda${local.postfix}" }, var.tags)
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sns:Publish",
            "Resource": [ "${local.notifications_topic_arn}" ],
            "Effect": "Allow"
        }
    ]
}
POLICY
}
