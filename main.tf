resource "aws_vpc" "main" {
  cidr_block       = "50.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "hd-pvt"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "50.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "hd-pvt-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "50.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "hd-pvt-subnet2"
  }
}

resource "aws_subnet" "pub-subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "50.0.3.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "hd-public-subnet1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "hd-igw"
  }
}

resource "aws_instance" "nat-instance" {
  ami           = "ami-00a9d4a05375b2763"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.pub-subnet1.id
  source_dest_check = false
  vpc_security_group_ids = [aws_security_group.nat_sg.id]
  tags = {
    Name = "HDapp-NATinstance"
  }
}

resource "aws_route_table" "privatert" {
  vpc_id = aws_vpc.main.id

  route = [
    {
      cidr_block = "0.0.0.0/0",
      instance_id = "${aws_instance.nat-instance.id}"
      carrier_gateway_id = null
      destination_prefix_list_id= null
      egress_only_gateway_id = null
       gateway_id= null
       ipv6_cidr_block = null
       local_gateway_id= null
       nat_gateway_id = null
        network_interface_id= null
        transit_gateway_id = null
        vpc_endpoint_id = null
        vpc_peering_connection_id = null
    }
  ]

  tags = {
    Name = "hdapp-NATRouteTable"
  }
  depends_on = [
    aws_instance.nat-instance
  ]
}

resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.main.id

  route = [
    {
      cidr_block = "0.0.0.0/0",
      instance_id = null
      carrier_gateway_id = null
      destination_prefix_list_id= null
      egress_only_gateway_id = null
       gateway_id= "${aws_internet_gateway.gw.id}"
       ipv6_cidr_block = null
       local_gateway_id= null
       nat_gateway_id = null
        network_interface_id= null
        transit_gateway_id = null
        vpc_endpoint_id = null
        vpc_peering_connection_id = null
    }
  ]

  tags = {
    Name = "hdapp-IGWRouteTable"
  }
  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_route_table_association" "sub1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.privatert.id
  depends_on = [
    aws_route_table.privatert
  ]
}

resource "aws_route_table_association" "sub2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.privatert.id
  depends_on = [
    aws_route_table.privatert
  ]
}

resource "aws_route_table_association" "pubsub1" {
  subnet_id      = aws_subnet.pub-subnet1.id
  route_table_id = aws_route_table.publicrt.id
  depends_on = [
    aws_route_table.publicrt
  ]
}

resource "aws_security_group" "nat_sg" {
  name        = "nat_sg"
  description = "Allow traffic for private subnet"
  vpc_id      = aws_vpc.main.id

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description = "egress 1"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      "self" = false
    }
  ]

  tags = {
    Name = "hdapp-nat-sg"
  }
}

resource "aws_security_group" "endpoint_sg" {
  name        = "endpoint_sg"
  description = "Allow traffic for endpoints"
  vpc_id      = aws_vpc.main.id

  ingress = [
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["50.0.0.0/16"]
      description = "ingress vpc endpoint"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      "self" = false
    }
  ]

  tags = {
    Name = "hdapp-endpoint-sg"
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Allow traffic for instances"
  vpc_id      = aws_vpc.main.id

  egress = [
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["50.0.0.0/16"]
      description = "ingress vpc endpoint"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      "self" = false
    }
  ]

  ingress = [
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["50.0.0.0/16"]
      description = "ingress vpc endpoint"
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      "self" = false
    }
  ]

  tags = {
    Name = "hdapp-instance-sg"
  }
}