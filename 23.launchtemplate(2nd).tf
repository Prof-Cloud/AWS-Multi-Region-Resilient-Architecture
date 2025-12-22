#Launch Template
#Secondary Region
resource "aws_launch_template" "app_template_2nd" {
  provider      = aws.London
  name_prefix   = "app_template_2nd"
  image_id      = data.aws_ami.linux_ami_2nd.id
  instance_type = "t3.micro"

  #Using existing Key Pair  
  key_name = "mykeypaor"

  vpc_security_group_ids = [aws_security_group.Linux_Server_2nd.id]

  user_data = filebase64("userdata.sh")



  lifecycle {
    create_before_destroy = true
  }

  #Attach Instance Profile
  #Secondary Region
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tags = {
    Name = "EC2 Launch Template - Secondary Region"
  }
}