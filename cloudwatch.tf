# =================================================================================
# CLOUDWATCH LOGS
# =================================================================================
# This file creates a CloudWatch Log Group. All EC2 instances in the Auto Scaling
# Group will be configured to send their application logs to this central location.
# =================================================================================

resource "aws_cloudwatch_log_group" "fastapi_app" {
  name              = "/fastapi/application"
  retention_in_days = 7 # Keep logs for 7 days

  tags = {
    Name = "Log group for FastAPI application"
  }
}