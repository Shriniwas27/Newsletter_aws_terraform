# =================================================================================
# APPLICATION LOAD BALANCER (ALB)
# =================================================================================
# This file sets up the Application Load Balancer, its target group, and a
# listener. The ALB distributes incoming HTTP traffic from the internet to the
# EC2 instances in the target group.
# =================================================================================


resource "aws_lb" "main" {
  name               = "fastapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = false

  tags = {
    Name = "fastapi-alb"
  }
}


resource "aws_lb_target_group" "main" {
  name     = "fastapi-tg"
  port     = 8000 # The port our FastAPI app listens on
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "fastapi-tg"
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}


