# =================================================================================
# MONITORING & ALERTING (SNS & CLOUDWATCH)
# =================================================================================
# This file sets up proactive monitoring for our infrastructure. It creates an SNS
# topic to send notifications, subscribes an email address to that topic, and
# creates CloudWatch alarms that trigger when specific thresholds are breached.
# =================================================================================


resource "aws_sns_topic" "alarms" {
  name = "fastapi-alarms-topic"
  tags = {
    Name = "SNS Topic for FastAPI Alarms"
  }
}


resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.notification_email
}



resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "fastapi-high-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm fires when the average CPU utilization of the FastAPI instances exceeds 80%."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}


resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "fastapi-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "180" # 3 minutes
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This alarm fires when there are unhealthy hosts in the ALB target group."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.main.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }
}


resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "fastapi-alb-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60" # 1 minute
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This alarm fires if the ALB reports any 5xx errors from the application."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.main.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }
}


resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "fastapi-rds-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm fires if the primary RDS instance CPU utilization exceeds 80%."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }
}


resource "aws_cloudwatch_metric_alarm" "rds_low_memory" {
  alarm_name          = "fastapi-rds-low-freeable-memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = "256000000" # 256 MB in bytes
  alarm_description   = "This alarm fires if the primary RDS instance has low freeable memory."
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }
}
