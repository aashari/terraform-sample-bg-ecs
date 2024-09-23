resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr_block

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-vpc"
  })
}

resource "aws_subnet" "public" {
  count = length(local.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-public-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "private" {
  count = length(local.private_subnet_cidrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = local.private_subnet_cidrs[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-private-subnet-${count.index + 1}"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(local.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-nat-gw"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count = length(local.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
