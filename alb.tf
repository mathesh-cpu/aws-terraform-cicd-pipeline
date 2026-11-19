# 1. Application Load Balancer (Public Front Door)
resource "aws_lb" "app_alb" {
  name               = "enterprise-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

# 2. Target Group (Health Checks & Routing Pool for EC2 Instances)
resource "aws_lb_target_group" "app_tg" {
  name     = "enterprise-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# 3. HTTP Listener (Forwards Port 80 Traffic to the Target Group)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 4. Output the Live ALB URL in GitHub Actions Logs
output "alb_dns_name" {
  description = "Public URL of the Application Load Balancer"
  value       = "http://${aws_lb.app_alb.dns_name}"
}