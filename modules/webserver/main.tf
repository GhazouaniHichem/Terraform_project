
// Configue firewall rules (Security Group) 
// Use the default security group

resource "aws_default_security_group" "default-sg" {

  vpc_id = var.vpc_id

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

resource "aws_instance" "myapp-server" {
  // Basic
  ami = "ami-0f5094faf16f004eb"
  instance_type = var.instance_type
  subnet_id = var.subnet_id
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