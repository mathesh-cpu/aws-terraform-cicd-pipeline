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
              sudo apt-get install -y docker.io curl
              sudo systemctl start docker
              sudo systemctl enable docker

              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
              AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
              HOSTNAME=$(hostname)

              sudo mkdir -p /opt/nginx-html
              echo '<!DOCTYPE html><html><head><title>AWS Enterprise Pipeline</title><style>body{font-family:Arial,sans-serif;text-align:center;padding:50px;background:#0f172a;color:#f8fafc;}.card{background:#1e293b;padding:30px;border-radius:12px;display:inline-block;border:1px solid #38bdf8;}h1{color:#38bdf8;}span{color:#4ade80;font-weight:bold;}</style></head><body><div class="card"><h1>AWS Enterprise Pipeline</h1><p>Served via Application Load Balancer + Dockerized Nginx</p><hr>' | sudo tee /opt/nginx-html/index.html > /dev/null
              echo "<p>Availability Zone: <span>$AZ</span></p>" | sudo tee -a /opt/nginx-html/index.html > /dev/null
              echo "<p>Instance ID: <span>$INSTANCE_ID</span></p>" | sudo tee -a /opt/nginx-html/index.html > /dev/null
              echo "<p>Server Hostname: <span>$HOSTNAME</span></p></div></body></html>" | sudo tee -a /opt/nginx-html/index.html > /dev/null

              sudo docker run -d --restart unless-stopped -p 80:80 -v /opt/nginx-html:/usr/share/nginx/html:ro nginx
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
    version = aws_launch_template.enterprise_app.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "enterprise-docker-server"
    propagate_at_launch = true
  }
}