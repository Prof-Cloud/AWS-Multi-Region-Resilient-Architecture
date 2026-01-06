#Launch Template
resource "aws_launch_template" "app_template" {
  name_prefix   = "app_template"
  image_id      = data.aws_ami.linux_ami.id
  instance_type = "t3.micro"

  #Using existing Key Pair  
  key_name = "basicapp01"

  network_interfaces {
    associate_public_ip_address = false # ASG is in private subnets
    security_groups             = [aws_security_group.Linux_Server.id]
  }

# Added Metadata Options for IMDSv2 reliability
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("userdata.sh", {

    #Cluster endpoint need to be global cluster endpoint
    #Because primary cluster only works for Virginia
    #If Virginia dies, the London ec2 will try to connect to dead DB
    db_endpoint = aws_rds_global_cluster.global_db.endpoint

    db_name     = aws_rds_global_cluster.global_db.database_name
    db_user     = aws_rds_cluster.primary_cluster.master_username
    db_password = aws_secretsmanager_secret_version.db_password_val.secret_string
    }
    )
  )


  lifecycle {
    create_before_destroy = true
  }

  #Attach Instance Profile
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tags = {
    Name = "EC2 Launch Template"
  }
}