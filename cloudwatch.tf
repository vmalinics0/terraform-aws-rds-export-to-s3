#
# Create an event rule to listen for RDS DB Cluster Snapshot Events
#
resource "aws_cloudwatch_event_rule" "rdsSnapshotCreation" {
  count       = var.enabled ? 1 : 0
  name        = "${local.prefix}rds-snapshot-creation${local.postfix}"
  description = "RDS Snapshot Creation"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.rds"
  ],
  "detail-type": [
    "RDS DB Cluster Snapshot Event"
  ]
}
PATTERN

  tags = merge({ Name = "${local.prefix}rds-snapshot-creation${local.postfix}" }, var.tags)
}

#
# Send the events captured by the rule above to an SNS Topic
#
resource "aws_cloudwatch_event_target" "rdsSnapshotCreationTopic" {
  count     = var.enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.rdsSnapshotCreation[0].name
  target_id = "SendToSNS"
  arn       = local.snapshots_events_topic_arn
}
