#
# Create an SNS Topic for receiving RDS Snapshot Events
#
resource "aws_sns_topic" "rdsSnapshotsEvents" {
  count = var.enabled && var.create_snapshots_events_topic ? 1 : 0
  name  = "${local.prefix}rds-snapshots-creation${local.postfix}"
  tags  = merge({ Name = "${local.prefix}rds-snapshots-creation${local.postfix}" }, var.tags)
}


resource "aws_sns_topic" "exportMonitorNotifications" {
  count = var.enabled && var.create_notifications_topic ? 1 : 0
  name  = "${local.prefix}rds-exports-monitor-notifications${local.postfix}"
  tags  = merge({ Name = "${local.prefix}rds-exports-monitor-notifications${local.postfix}" }, var.tags)
}

#
# Allow CloudWatch to publish events on the SNS Topics
#
resource "aws_sns_topic_policy" "rdsSnapshotsEventsPolicy" {
  count  = var.enabled && var.create_snapshots_events_topic ? 1 : 0
  arn    = aws_sns_topic.rdsSnapshotsEvents[0].arn
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "SNS:Publish",
            "Resource": "${aws_sns_topic.rdsSnapshotsEvents[0].arn}"
        }
    ]
}
POLICY
}

#
# Subscribe Lambdas to the Topics
#
resource "aws_sns_topic_subscription" "lambdaRdsSnapshotToS3Exporter" {
  count     = var.enabled ? 1 : 0
  topic_arn = local.snapshots_events_topic_arn
  protocol  = "lambda"
  endpoint  = module.start_export_task_lambda.lambda_function_arn
}

resource "aws_sns_topic_subscription" "lambdaRdsSnapshotToS3Monitor" {
  count     = var.enabled ? 1 : 0
  topic_arn = local.snapshots_events_topic_arn
  protocol  = "lambda"
  endpoint  = module.monitor_export_task_lambda.lambda_function_arn
}

#
# Allow SNS Topics to trigger Lambda
#
resource "aws_lambda_permission" "snsCanTriggerStartExportTask" {
  count         = var.enabled ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.start_export_task_lambda.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = local.snapshots_events_topic_arn
}

resource "aws_lambda_permission" "snsCanTriggerMonitorExportTask" {
  count         = var.enabled ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.monitor_export_task_lambda.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = local.snapshots_events_topic_arn
}
