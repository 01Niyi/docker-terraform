#configuring aws provider with proper credentials (backend). This also means authenticating with aws
provider "aws" {
  region  = "us-east-1"
}


# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc_n" {
  tags = {
    Name = "my default vpc"
  }
}


# use data source to get all avalablility zones in region
data "aws_availability_zones" "all_available_zones" {}


# create default subnet if one does not exit
resource "aws_default_subnet" "default_az11" {
  availability_zone = data.aws_availability_zones.all_available_zones.names[0]

  tags = {
    Name = "default subnet"
  }
}


# create security group for the ec2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "allow access on ports 80 and 22"
  vpc_id      =  aws_default_vpc.default_vpc_n.id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks =  ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_sg"
  }
}


# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"] 

   filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

}


# launch the ec2 instance
resource "aws_instance" "ec2_instance_n" {
  ami                    = data.aws_ami.amazon_linux_2.id 
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az11.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = "ec2_key"

  tags = {
    Name = "ec2_instance_n"
  }
}


# an empty resource block
resource "null_resource" "null_name_n" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/ec2_key.pem")
    host        = aws_instance.ec2_instance_n.public_ip
  }

  # copy the password file for your docker hub account
  # from your computer (in the Downloads folder) to the ec2 instance (home directory) 
  provisioner "file" {
    source      = "~/Downloads/my_password.txt"
    destination = "/home/ec2-user/my_password.txt"
  }

  # copy the dockerfile from your computer to the ec2 instance 
  provisioner "file" {
    source      = "Dockerfile"
    destination = "/home/ec2-user/Dockerfile"
  }

  # copy the nn2.sh from your computer to the ec2 instance
  # remember, the neyorter.sh is the shell script that contains the commands
  # for building rhe docker image 

  provisioner "file" {
    source      = "nn2.sh"
    destination = "/home/ec2-user/nn2.sh"
  }

  # set permissions and run the neyorter.sh shell script that will be used to build the docker image
  # first line in the inline: make the neyorter.sh file executable
  # second line i the inline parameter: execute the file

  provisioner "remote-exec" {
    inline = [ 
      "sudo chmod +x /home/ec2-user/nn2.sh", 
      "sh /home/ec2-user/nn2.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.ec2_instance_n]

}


# print the url of the container
#we want to join http:// with the public_dns of the ec2 instance
output "container_url" {
  value = join("", ["http://", aws_instance.ec2_instance_n.public_dns])
}
