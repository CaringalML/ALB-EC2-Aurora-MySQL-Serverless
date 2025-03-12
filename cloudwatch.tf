# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${aws_lb.app.arn_suffix}", { "stat": "Sum", "period": 300 } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${var.region}",
        "title": "ALB Request Count"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "${aws_lb.app.arn_suffix}", { "stat": "Sum", "period": 300 } ],
          [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${aws_lb.app.arn_suffix}", { "stat": "Sum", "period": 300 } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${var.region}",
        "title": "ALB Error Counts"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${aws_autoscaling_group.app.name}", { "stat": "Average", "period": 300 } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${var.region}",
        "title": "EC2 CPU Utilization"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${aws_autoscaling_group.app.name}", { "stat": "Average", "period": 60 } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${var.region}",
        "title": "ASG Instance Count"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 12,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/WAFV2", "BlockedRequests", "WebACL", "${var.project_name}-web-acl", "Region", "${var.region}", { "stat": "Sum", "period": 300 } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${var.region}",
        "title": "WAF Blocked Requests"
      }
    },
    {
      "type": "log",
      "x": 12,
      "y": 12,
      "width": 12,
      "height": 6,
      "properties": {
        "query": "SOURCE '/aws/ec2/${var.project_name}/docker' | fields @timestamp, @message\n| sort @timestamp desc\n| limit 20",
        "region": "${var.region}",
        "title": "Docker Container Logs",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 18,
      "width": 24,
      "height": 6,
      "properties": {
        "query": "SOURCE '/var/log/syslog' | fields @timestamp, @message\n| sort @timestamp desc\n| limit 20",
        "region": "${var.region}",
        "title": "EC2 System Logs",
        "view": "table"
      }
    }
  ]
}
EOF
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors ALB 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_4xx" {
  alarm_name          = "${var.project_name}-target-4xx-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 50
  alarm_description   = "This metric monitors target 4XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# Optional: SNS Topic Subscription (uncomment and modify if needed)
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email"
#   endpoint  = "admin@example.com"
# }

# CloudWatch Logs Group for System logs
resource "aws_cloudwatch_log_group" "system" {
  name              = "/var/log/syslog"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-system-log"
  }
}

# CloudWatch Logs Group for Docker
resource "aws_cloudwatch_log_group" "docker" {
  name              = "/aws/ec2/${var.project_name}/docker"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-docker-log-group"
  }
}

# CloudWatch Logs Group for ALB Access Logs
resource "aws_cloudwatch_log_group" "alb" {
  name              = "/aws/alb/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-alb-log-group"
  }
}

# CloudWatch Logs Group for WAF logs
resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/wafv2/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-waf-log-group"
  }
}

# ALB with CloudWatch Logs
resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false  # Set to false to allow deletion
  
  # Disable access logs
  access_logs {
    bucket  = "" 
    prefix  = ""
    enabled = false
  }

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Random string generator for resource uniqueness
resource "random_string" "suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}