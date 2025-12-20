#Launch Template
resource "aws_launch_template" "app_template" {
  name_prefix   = "app_template"
  image_id      = data.aws_ami.linux_ami.id
  instance_type = "t3.micro"

  #Using existing Key Pair  
  key_name = "basicapp01"

  vpc_security_group_ids = [aws_security_group.Linux_Server.id]

  user_data = filebase64("userdata.sh")



  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "EC2 Launch Template"
  }
}