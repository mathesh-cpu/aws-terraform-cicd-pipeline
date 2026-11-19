# 1. Find the latest Ubuntu OS automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Official Canonical Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 2. The Server Blueprint (Launch Template)
resource "aws_launch_template" "enterprise_app" {
  name_prefix   = "enterprise-app-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # The automated startup script
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install docker.io -y
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run -d -p 80:80 nginx
              EOF
  )
}

# 3. The Server Factory (Auto Scaling Group)
resource "aws_autoscaling_group" "enterprise_asg" {
  name                = "enterprise-autoscaling-group"
  vpc_zone_identifier = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  target_group_arns         = [aws_lb_target_group.app_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  desired_capacity    = 2
  max_size            = 4
  min_size            = 1

  launch_template {
    id      = aws_launch_template.enterprise_app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "enterprise-docker-server"
    propagate_at_launch = true
  }
}