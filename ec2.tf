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

# Launch template for the EC2 instances
resource "aws_launch_template" "app" {
  name_prefix            = "${var.project_name}-launch-template-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2.id]
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Update packages and install docker
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common awscli
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce

    # Start docker service
    systemctl enable docker
    systemctl start docker

    # Configure AWS CLI and login to ECR
    export AWS_DEFAULT_REGION=ap-southeast-2
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REPOSITORY="${var.ecr_repository_name}"
    ECR_URL="$ACCOUNT_ID.dkr.ecr.ap-southeast-2.amazonaws.com"
    
    # Login to ECR
    aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin $ECR_URL
    
    # Pull the latest image
    docker pull $ECR_URL/$ECR_REPOSITORY:latest
    
    # Stop any running container
    docker stop $(docker ps -a -q) 2>/dev/null || true
    docker rm $(docker ps -a -q) 2>/dev/null || true
    
    # Run the new container
    docker run -d -p 80:80 $ECR_URL/$ECR_REPOSITORY:latest
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
  min_size                  = 2  # Start with 2 instances
  max_size                  = 4  # Scale up to maximum of 4 instances
  desired_capacity          = 2  # Initial desired capacity of 2 instances
  vpc_zone_identifier       = aws_subnet.private[*].id
  default_cooldown          = 300  # 5-minute cooldown period in seconds
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  target_group_arns = [aws_lb_target_group.app.arn]
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
  
  estimated_instance_warmup = 300  # 5-minute warmup period in seconds
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0 # Target CPU utilization of 70%
    disable_scale_in = false
  }
}

