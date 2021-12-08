#
# KMS Policy 
#
data "aws_iam_policy_document" "snapshotExportEncryptionKeyPolicy" {
  count = var.create_customer_kms_key ? 1 : 0

  statement {
    sid = "Allow administration of the key to the account"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "Allow usage of the key"

    principals {
      type        = "AWS"
      identifiers = ["${module.start_export_task_lambda.lambda_role_arn}"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [
      "*",
    ]
  }


  statement {
    sid = "Allow grants on the key"

    principals {
      type        = "AWS"
      identifiers = ["${module.start_export_task_lambda.lambda_role_arn}"]
    }

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [
        "true"
      ]
    }
  }
}

#
# This key will be used for encrypting snapshots exported to S3
#
resource "aws_kms_key" "snapshotExportEncryptionKey" {
  count       = var.create_customer_kms_key ? 1 : 0
  description = "Snapshot Export Encryption Key"
  tags        = merge({ Name = "${local.prefix}kms-rds-snapshot-key${local.postfix}" }, var.tags)
  policy      = var.enabled ? data.aws_iam_policy_document.snapshotExportEncryptionKeyPolicy.json : null
}

#
# Key alias
#
resource "aws_kms_alias" "snapshotExportEncryptionKey" {
  count         = var.create_customer_kms_key ? 1 : 0
  name          = "alias/${local.prefix}rds-snapshot-export${local.postfix}"
  target_key_id = aws_kms_key.snapshotExportEncryptionKey[0].key_id
}
