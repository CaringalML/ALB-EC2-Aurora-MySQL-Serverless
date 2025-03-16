# Latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# SSM Parameter to track the image version
resource "aws_ssm_parameter" "app_image_version" {
  name        = "/${var.project_name}/app/image-version"
  description = "Current app image version to deploy"
  type        = "String"
  value       = "latest"  # Initial value

  tags = {
    Name = "${var.project_name}-app-image-version"
  }
}




# Launch template for the EC2 instances
resource "aws_launch_template" "app" {
  name_prefix            = "${var.project_name}-launch-template-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update system and install dependencies
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common awscli

    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce

    # Start Docker service
    systemctl enable docker
    systemctl restart docker

    # Define AWS region and ECR repository
    AWS_REGION="ap-southeast-1"
    ECR_REPO="939737198590.dkr.ecr.ap-southeast-1.amazonaws.com/my-api"

    # Authenticate Docker with AWS ECR
    $(aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO)

    # Pull the latest image from ECR
    docker pull $ECR_REPO:latest

    # Stop and remove any existing container
    docker stop my-api 2>/dev/null || true
    docker rm my-api 2>/dev/null || true

    # Run the container
    docker run -d -p 80:80 \
      --name my-api \
      $ECR_REPO:latest

    # Create a simple health check script
    cat > /usr/local/bin/health-check.sh <<'HEALTHSCRIPT'
    #!/bin/bash
    AWS_REGION="ap-southeast-1"
    ECR_REPO="939737198590.dkr.ecr.ap-southeast-1.amazonaws.com/my-api"

    # Check if container is running
    if [ $(docker ps -q -f name=my-api | wc -l) -eq 0 ]; then
      echo "Container not running, restarting..."
      docker start my-api || (
        # If container can't be started, pull and run a new one
        docker rm my-api
        $(aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO)
        docker pull $ECR_REPO:latest
        docker run -d -p 80:80 --name my-api $ECR_REPO:latest
      )
    fi
    HEALTHSCRIPT
    chmod +x /usr/local/bin/health-check.sh

    # Set up a cron job to run the health check every 5 minutes
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/health-check.sh >> /var/log/container-health-check.log 2>&1") | crontab -
  EOF
  )

  # Reference the IAM instance profile from iam.tf
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}




# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = aws_subnet.private[*].id
  default_cooldown          = 300
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-asg"
    propagate_at_launch = true
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# CPU Target Scaling Policy
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${var.project_name}-cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"
  
  estimated_instance_warmup = 300
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
    disable_scale_in = false
  }
}

# Add IAM permissions to allow EC2 to access SSM Parameter Store
resource "aws_iam_policy" "ssm_parameter_access" {
  name        = "${var.project_name}-ssm-parameter-access"
  description = "Allow EC2 instances to access SSM parameters"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Resource = "arn:aws:ssm:${var.region}:*:parameter/${var.project_name}/*"
      }
    ]
  })
}

# Attach the SSM Parameter Store policy to the EC2 role
resource "aws_iam_role_policy_attachment" "ssm_parameter_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ssm_parameter_access.arn
}