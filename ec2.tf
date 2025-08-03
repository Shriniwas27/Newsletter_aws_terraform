# =================================================================================
# COMPUTE (EC2 LAUNCH TEMPLATE & AUTO SCALING GROUP) - UBUNTU VERSION
# =================================================================================
# This file defines the compute layer. It creates a Launch Template that specifies
# the configuration for our EC2 instances (AMI, instance type, user data script)
# and an Auto Scaling Group to manage these instances.
# =================================================================================


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



resource "aws_launch_template" "main" {
  name_prefix   = "fastapi-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

 
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  
  user_data = base64encode(<<-EOF
             
              apt-get update -y
             
              apt-get install -y git python3-pip netcat-openbsd unzip
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

            
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
              dpkg -i -E ./amazon-cloudwatch-agent.deb
              
              
              cat << 'EOT' > /opt/aws/amazon-cloudwatch-agent/bin/config.json
              {
                "agent": {
                  "run_as_user": "root"
                },
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/var/log/fastapi_app.log",
                          "log_group_name": "${aws_cloudwatch_log_group.fastapi_app.name}",
                          "log_stream_name": "{instance_id}"
                        }
                      ]
                    }
                  }
                }
              }
              EOT

            
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

             
              git clone https://github.com/Shriniwas27/newsletter_aws.git /home/ubuntu/repo
              chown -R ubuntu:ubuntu /home/ubuntu/repo
              cd /home/ubuntu/repo
             
              pip3 install -r requirements.txt

            
              echo "Fetching database credentials from Secrets Manager..."
              SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_password.id} --region ${var.aws_region} --query SecretString --output text)
              
              
              export DB_PASSWORD=$(echo $SECRET_JSON | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])")

              DB_HOST="${aws_db_instance.primary.address}"
              echo "Waiting for database to become available..."
              while ! nc -z $DB_HOST 5432; do   
                sleep 5
                echo "Retrying database connection..."
              done
              echo "Database is available! Starting application."

              touch /var/log/fastapi_app.log
            
              chown ubuntu:ubuntu /var/log/fastapi_app.log
              
              sudo -u ubuntu sh -c " \
                export WRITER_DATABASE_URL='postgresql://${var.db_username}:$${DB_PASSWORD}@${aws_db_instance.primary.address}/${var.db_name}'; \
                export READER_DATABASE_URL='postgresql://${var.db_username}:$${DB_PASSWORD}@${aws_db_instance.replica.address}/${var.db_name}'; \
                export STAGE='production'; \
                /usr/local/bin/uvicorn fastapi_app.main:app --host 0.0.0.0 --port 8000 &> /var/log/fastapi_app.log & \
              "
              EOF
  )

  tags = {
    Name = "fastapi-launch-template"
  }
}


resource "aws_autoscaling_group" "main" {
  name                = "fastapi-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [for subnet in aws_subnet.public : subnet.id]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.main.arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "fastapi-ec2-instance"
    propagate_at_launch = true
  }
}
