
resource "aws_lb" "web_server" {
  name               = "${local.prefix_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-alb"
  })
}

resource "aws_lb_listener" "web_server" {
  load_balancer_arn = aws_lb.web_server.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_blue.arn
  }
}

resource "aws_lb_target_group" "web_server" {
  name        = "${local.prefix_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-tg"
  })
}

resource "aws_security_group" "alb" {
  name        = "${local.prefix_name}-alb-sg"
  description = "Allow inbound traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-alb-sg"
  })
}
