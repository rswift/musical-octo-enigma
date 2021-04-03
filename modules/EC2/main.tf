#
# EC2 instance
#

#
# a bit blunt, but for what we need this should mean any region will work...
#
data "aws_ami" "ssh" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "ssh" {
  ami           = data.aws_ami.ssh.id
  instance_type = var.ssh_instance_type
  subnet_id     = var.subnet_id

  #
  # For the avoidance of doubt...
  #
  associate_public_ip_address = false

  #
  # As of today, an update is needed to the SSM Agent to get a version that supports
  # streaming to CloudWatch Logs...
  #
  # See: https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-al2.html
  #
  user_data = file("${path.module}/update-ssm-agent.sh")

  iam_instance_profile                 = aws_iam_instance_profile.ssh.name
  instance_initiated_shutdown_behavior = var.shutdown_behaviour
  vpc_security_group_ids               = var.security_group_id

  tags = {
    Name               = var.tag_Name
    "cost:allocation"  = var.tag_cost_allocation
    "resource:context" = var.tag_resource_context
  }

  #
  # Force EC2 to wait on the creation of the profile... it seemed to cause an issue
  # when this
  #
  depends_on = [
    aws_iam_instance_profile.ssh, aws_iam_role.ssh
  ]
}

#
# The EC2 instance needs an IAM polocy (known as an instance policy) to be
# attached in order to permit the Session Manager connectivity
#
resource "aws_iam_instance_profile" "ssh" {
  name = "ssm_profile"
  role = aws_iam_role.ssh.name
}

resource "aws_iam_role" "ssh" {
  name        = "ssm_for_ec2-role"
  description = "Enable SSM access into EC2"

  assume_role_policy  = data.aws_iam_policy_document.instance-assume-role-policy.json
  managed_policy_arns = [aws_iam_policy.ssm_for_ec2.arn]
}

resource "aws_iam_policy" "ssm_for_ec2" {
  name        = "ssm_for_ec2-policy"
  description = "Permit the EC2 instance to receive connections via Session Manager"

  path   = "/"
  policy = data.aws_iam_policy_document.ssm_for_ec2.json
}

data "aws_iam_policy_document" "ssm_for_ec2" {
  statement {
    sid = "AllowSessionManager"

    actions = [
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:CreateControlChannel",

      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",

      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:DescribeAssociation",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"    
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "AllowWriteToCloudWatchLogs"

    effect  = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    sid = "AllowPutCloudWatchLogEvents"

    effect  = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:*"
    ]
  }

  statement {
    sid = "AllowWriteToCloudWatchMetrics"

    actions = [
      "cloudwatch:PutMetricData"
    ]

    resources = [
      "*",
    ]
  }

}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#
# Create the CloudWatch Log Group
#
resource "aws_cloudwatch_log_group" "ssh" {
  name              = var.log_group_name
  retention_in_days = "1"

 tags = {
    Name              = var.tag_Name
    "cost:allocation" = var.tag_cost_allocation
  }
}