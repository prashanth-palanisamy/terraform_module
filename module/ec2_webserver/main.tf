#fetching latest ami from amazon
data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

#Ec2 instance creation 
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  subnet_id = "subnet-018aa08f4cfcf9db9"   # replace subnet with your VPC subnet
  key_name = "Ec2_keypair"


  # Configure the public IP address
  associate_public_ip_address = true

  # Configure the security group
  security_groups = [
    aws_security_group.web_security_group.id
  ]

  # Configure user data to install Nginx and create a script to fetch EC2 metadata
  user_data = <<-EOF
    #!/bin/bash

    sudo yum update -y

    sudo amazon-linux-extras install nginx1 -y
    sudo yum install -y apache2-utils

    # Create a script to fetch EC2 metadata and display it in a webpage
    echo '<html>' >> index.html
    echo '<head>' >> index.html
    echo '<title>EC2 Metadata</title>' >> index.html
    echo '</head>' >> index.html
    echo '<body>' >> index.html

    # Get the instance ID from EC2 metadata
    instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)

    echo "<p>Instance ID: $instance_id</p>" >> index.html

    # Get the public IP address from EC2 metadata
    public_ip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
    echo "<p>Public IP Address: <a href=\"http://$public_ip\">$public_ip</a></p>" >> index.html

    echo '</body>' >> index.html
    echo '</html>' >> index.html

    sudo mv index.html /usr/share/nginx/html/index.html

    # Start the Nginx web server
    sudo service nginx start
  EOF

  # Configure metadata options to access EC2 metadata
  metadata_options {
    http_endpoint = "enabled"
  }
}

resource "aws_security_group" "web_security_group" {
  name        = "web_security_group"
  description = "Security group for the web server"

  # Allow incoming HTTP traffic on port 80
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


output "public_ip" {
  value = aws_instance.web.public_ip
}
