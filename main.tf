terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "ap-south-1"
}
# Latest Ubuntu 24.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
# EC2 Instance
resource "aws_instance" "monitor" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  user_data_replace_on_change = true
  user_data                   = <<-EOF
   #!/bin/bash
   set -eux
   for i in 1 2; do
     nohup yes > /dev/null 2>&1 &
   done
   sleep 900
   pkill -x yes || true
 EOF
  tags = {
    Name = "project3-monitoring-ec2"
  }
}
# CloudWatch CPU Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "project3-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Alarm when EC2 CPU usage exceeds 20 percent"
  treat_missing_data  = "notBreaching"
  dimensions = {
    InstanceId = aws_instance.monitor.id
  }
}
# Outputs
output "instance_id" {
  value = aws_instance.monitor.id
}
output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.cpu_alarm.alarm_name
}
