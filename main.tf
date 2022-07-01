provider "aws" {
  region = "eu-west-3"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable "env_prefix" {} 
variable "my_ip" {}
variable "instance_type" {}
//variable "public_key_location" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
      Name: "${var.env_prefix}-vpc"
  }
}


resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
      Name: "${var.env_prefix}-subnet-1"
  }
}


resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

// Create a New route table and associate a subnet


/*
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}


resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-rtb"
  }
}

*/


// Use the default route table and do all stuff needed


resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-main-rtb"
  }
}


// Configue firewall rules (Security Group) 

/*
resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  // incoming traffic
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //outgoing traffic
  egress {
    from_port = 0 //any port 0
    to_port = 0
    protocol = "-1" //any protocol -1
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = [] // allowing access to any vpc
  }
  tags = {
      Name: "${var.env_prefix}-sg"
    }

}
*/

// Use the default security group

resource "aws_default_security_group" "default-sg" {

  vpc_id = aws_vpc.myapp-vpc.id

  // incoming traffic
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //outgoing traffic
  egress {
    from_port = 0 //any port 0
    to_port = 0
    protocol = "-1" //any protocol -1
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = [] // allowing access to any vpc
  }
  tags = {
      Name: "${var.env_prefix}-default-sg"
    }  
}


// Create an EC2 instance

//get the ami image ID automatically from aws with specified (filter)

/*

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

// Then reference it in the "aws_instance" resource with:
   ami = data.aws_ami.latest-amazon-linux-image.id

*/

/*
// Create KEy-pair

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
}

// reference it : key_name = aws_key_pair.ssh-key.key_name


*/

resource "aws_instance" "myapp-server" {
  // Basic
  ami = "ami-0f5094faf16f004eb"
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
  availability_zone = var.avail_zone
  
  associate_public_ip_address = true

  // Key pair to ssh to the instance
  // needs more commannds after creating key-pair manually (aws recommended):
  // mv ~Downloads/*.pem ~/.ssh
  // chmod 400 ~/.ssh/*.pem


  key_name = "server-key-pair"


  // AUtomate all tasks
  // Execute a cmd on server
  // Entrypoint to execute when server is instanciated
  // keep in mind that user_data block execute once, when we re apply any change, it not will be execute

  user_data = file("entry-script.sh")
  
  tags = {
    Name = "${var.env_prefix}-server"
  }

}