# =================================================================================
# MONITORING & ALERTING (SNS & CLOUDWATCH)
# =================================================================================
# This file sets up proactive monitoring for our infrastructure. It creates an SNS
# topic to send notifications, subscribes an email address to that topic, and
# creates CloudWatch alarms that trigger when specific thresholds are breached.
# =================================================================================

# --- SNS Topic ---
# Create an SNS topic that will be the destination for all CloudWatch alarm notifications.
resource "aws_sns_topic" "alarms" {
  name = "fastapi-alarms-topic"
  tags = {
    Name = "SNS Topic for FastAPI Alarms"
  }
}

# --- SNS Subscription ---
# Subscribe the email address defined in variables.tf to the SNS topic.
# IMPORTANT: AWS will send a confirmation email to this address. You must click
# the link in that email to confirm the subscription and start receiving alerts.
resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.notification_email
}


# --- CloudWatch Alarms ---

# Alarm 1: High CPU Utilization (EC2)
# This alarm will trigger if the average CPU usage across all EC2 instances
# in the Auto Scaling Group is above 80% for 5 consecutive minutes.
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

# Alarm 2: Unhealthy Hosts (ALB Target Group)
# This alarm will trigger if there is at least one unhealthy host in the
# Application Load Balancer's target group for 3 consecutive minutes.
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

# --- OPTIMIZATION 1: ALB 5xx Errors ---
# This alarm will trigger if the load balancer reports any 5xx server-side errors.
# This is crucial for catching application-level bugs even if the hosts are "healthy".
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

# --- OPTIMIZATION 2: RDS High CPU Utilization ---
# This alarm will trigger if the primary database CPU is over 80% for 10 minutes.
# This can be an early indicator of inefficient queries or an undersized instance.
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

# --- OPTIMIZATION 3: RDS Low Freeable Memory ---
# This alarm will trigger if the database's freeable memory drops below 256MB.
# Low memory is a common cause of poor database performance.
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
