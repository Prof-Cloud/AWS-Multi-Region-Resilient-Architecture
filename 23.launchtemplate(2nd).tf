#Launch Template
#Secondary Region
resource "aws_launch_template" "app_template_2nd" {
  provider      = aws.London
  name_prefix   = "app_template_2nd"
  image_id      = data.aws_ami.linux_ami_2nd.id
  instance_type = "t3.micro"

  #Using existing Key Pair  
  key_name = "mykeypaor"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.Linux_Server_2nd.id]
  }

  # Added Metadata Options for IMDSv2 reliability
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("userdata_london.sh", {
    db_endpoint = aws_rds_cluster.secondary_cluster.endpoint
    db_name     = aws_rds_global_cluster.global_db.database_name
    db_user     = aws_rds_cluster.primary_cluster.master_username
    db_password = aws_secretsmanager_secret_version.db_password_val.secret_string
    asg_name    = "vanish-app-asg-secondary"
    }
    )
  )

  # Ensure the London replica is up before London EC2s start
  depends_on = [aws_rds_cluster_instance.secondary_instances,
  aws_nat_gateway.nat_2nd]

  lifecycle {
    create_before_destroy = true
  }


  #Attach Instance Profile
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile_2nd.name
  }

  tags = {
    Name = "EC2 Launch Template London"
  }
}


