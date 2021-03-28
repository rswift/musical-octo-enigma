# Introduction
In support of a natter about how to access the command line of an EC2 instance running Linux, this repo contains the Terraform configuration to create a VPC with associated resources, and an EC2 instance. The [Security Group](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html "Security Group") has no ingress rules at all, and only has egress rules back to the AWS `ssm`, `ssmmessages` & `ec2messages` endpoints. The route table also has explicit routes for these endpoints (via CIDR ranges). Neither the security group or route table references `0.0.0.0/0`. Note that this is *only required* to avoid the need to further complicate this demo by requiring [VPN](https://docs.aws.amazon.com/vpc/latest/userguide/vpn-connections.html "VPN") and [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/userguide/endpoint-services-overview.html "VPC Endpoints").

## Costs
Running the configuration here could (most likely will) result in charges, albeit modest. But please be aware that this is a possibility before you `terraform apply`!

## Eventual Consistency
I've noticed that on occasion, eventual consistency can result in things seeming not to have worked, for example, attempting to connect to an EC2 instance, within a few seconds of it being born could result in errors such as:
`An error occurred (TargetNotConnected) when calling the StartSession operation: i-0xdeadbeef is not connected.`

## CloudWatch Log Group
The Terraform included in this repo is entirely self-contained, so be aware that `terraform destroy` will remove the CloudWatch Log Group that is created, meaning that any log streams in the log group will also vanish. So access those log streams before removing the resources, or tinker with the configuration and move the log group out of the [EC2 main.tf](./modules/EC2/main.tf "EC2 main.tf") file as you wish.

Note that as of today, the Amazon Linux 2 image (see [release notes](https://aws.amazon.com/amazon-linux-2/release-notes/ "Amazon Linux 2 Release Notes")) is pre-installed with v3.0.161.0-1 of the amazon-ssm-agent, which does not support the real time streaming as that [didn't arrive until v3.0.356.0](https://github.com/aws/amazon-ssm-agent/blob/master/RELEASENOTES.md "SSM Agent Release Notes") which is a shame... ¯\_(ツ)_/¯

# Terraform
This has been written using [Terraform](https://learn.hashicorp.com/collections/terraform/aws-get-started "Terraform") `v0.14.8` (see [provider.tf](./provider.tf "provider.tf")) but should work fine with any version from v0.12 onwards.

# AWS
The resources created are:
* A new VPC with a modified route table, a managed prefix list, a security group and an Internet Gateway; the NACL is default
* A CloudWatch Log Group
* An EC2 instance with instance profile, in the private subnet, but it has a public IP address purely to allow the connection without needing VPN+VPC Endpoint

This doesn't create a user or IAM role to control access to Systems Manager, it is assumed that for this demo, you'll have logical access that facilitates that. Also, in [provider.tf](./provider.tf "provider.tf"), this configuration assumes a role in a second account, if you only have one account, simply comment out the `assume_role` section.

The file [terraform.tfvars](./terraform.tfvars "terraform.tfvars") is not committed to the repo, but it looks like this:
`terraform.tfvars` defines:
```terraform
#
# Externalise all the variables from the configuration
#
aws_profile = "default"

#
# The AWS account number of the account where the function will be deployed into
#
target_account = xxxxxxxxxxxx
```
If you've only got one account, then the `target_account` entry isn't needed.

## CIDR Ranges
The two CIDR ranges for the required AWS endpoints were reverse engineered, specifically for the London `eu-west-2` region. These CIDR ranges may coverf other regions, but I cannot guarantee that. So if this doesn't work, definitely give the [AWS IP ranges](https://docs.aws.amazon.com/general/latest/gr/aws-ip-ranges.html "AWS IP Ranges") page a once over and check the [latest file](https://ip-ranges.amazonaws.com/ip-ranges.json "ip-ranges.json").

## AWS Access
It is assumed that you already have an AWS account and have the ability to invoke the command line using the AWS [shared credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html "AWS Shared Credentials File"). In addition to the credentials, I also set the config file and use a profile.

The [AWS CLI (v2)](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html "AWS CLI v2") is installed too, it is required for access but it's very useful to prove programmatic connectivity from the client into AWS with parameters like `--profile`, an example if there are problems with access could be:
```bash
export PROFILE=my_profile_name
aws iam get-user --profile ${PROFILE} --debug
```
far easier than trying to determine why programmatic access isn't working via Terraform!

# Resources
Use the command line `-auto-approve` if you don't want to have to answer yes when creating or destroying resources.

## Initialisation
```bash
echo "{repo root} is probably the project you've cloned from github so replace with the directory name" > /dev/null
cd {repo root}
terraform init
```

## Creation
```bash
terraform apply
```

## Removal
```bash
terraform destroy
```

# Connecting
So, the main goal. If you've successfully created the VPC and EC2 instance plus the associated resources, we'll now go ahead and connect.

## Via the AWS Console
Log on to the AWS console and navigate to the [Session Manager](https://eu-west-2.console.aws.amazon.com/systems-manager/session-manager/start-session?region=eu-west-2
 "AWS Session Manager") console. There should be an instance with the name `SSH no port 22` (unless you've changed the configuration), so click the radio button and then the big orange `Start Session` button - a terminal window will open in a browser tab and you'll have the EC2 command line available to you...

## Via the Command Line
To use the command line, the session manager plugin is needed, see [this documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html "Session Manager plugin"), so assuming you've got that and the CLI is installed, you can retrieve running instances:
```bash
aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[*].Instances[*].[InstanceId]' --output text
```
which will show the ID of running instances. That value is an input to the following:
```bash
aws ssm start-session --target {instance ID}
```
but if you only have one running instance, and are using a *nix shell, this'll probably work:
```bash
aws ssm start-session --target `aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[*].Instances[*].[InstanceId]' --output text`
```

## What could go wrong?
Plenty. Assuming you've not tried to log on within seconds of the EC2 instance being created, it could be that the CIDR ranges aren't correct because of the region you are using, or something has changed elsewhere (I did reverse engineer them, purely to show that `0.0.0.0/0` wasn't required). The easiest way to check would be to add `0.0.0.0/0` to the route table and managed prefix list.

There are obviously other things that could be a problem, but I'm assuming that if you are sophisticated enough to need command line access, you should have the ability to troubleshoot too ;)

# Other Stuff...

## nmap
Be mindful that this could be deemed as a threat to AWS, so do this at your own risk!
Given the EC2 instance has a public IP address, to check what ports are open, something like:
```bash
read PUBLIC_IP_OF_EC2
sudo nmap -p- -sT -Pn ${PUBLIC_IP_OF_EC2}
```
will probe for open ports from 1 to 65535, won't check if the host is up and will take its time... Assuming this works, you shouldn't get any SSH ports!

## SSM Preferences
Optionally, to configure [SSM preferences](https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-configure-preferences-cli.html "SSM Preferences") modify the [ssm_preferences.json](./ssm_preferences.json "ssm_preferences.json") file as you wish, then:
```bash
aws ssm update-document --name "SSM-SessionManagerRunShell" --content "file://ssm_preferences.json" --document-version "\$LATEST"
```

## Logging Output
Here is an example of logged output:
```
Script started on 2021-03-15 11:41:00+0000
[?1034hsh-4.2$ 
[Ksh-4.2$ echo "I am an example of session logging! ":)"
I am an example of session logging! :)
sh-4.2$ exit
exit

Script done on 2021-03-15 11:41:00+0000
```

## StartSession API
The following is an example of the [`StartSession`](https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_StartSession.html "SSM StartSession API") API call from CloudTrail:
```json
{
    "eventVersion": "1.08",
    "userIdentity": {
        "type": "IAMUser",
        "principalId": "AKIA5AKT4G3CG6EVC8D4",
        "arn": "arn:aws:iam::123456789012:user/robert",
        "accountId": "123456789012",
        "accessKeyId": "AKIA5AKT4G3CG6EVC8D4",
        "userName": "robert"
    },
    "eventTime": "2021-03-15T20:28:17Z",
    "eventSource": "ssm.amazonaws.com",
    "eventName": "StartSession",
    "awsRegion": "eu-west-2",
    "sourceIPAddress": "1.2.3.4",
    "userAgent": "aws-cli/2.1.30 Python/3.9.2 Darwin/20.3.0 source/x86_64 prompt/off command/ssm.start-session",
    "requestParameters": {
        "target": "i-0xdeadbeef"
    },
    "responseElements": {
        "sessionId": "robert-0d225423a59c47fc5",
        "tokenValue": "Value hidden due to security reasons.",
        "streamUrl": "wss://ssmmessages.eu-west-2.amazonaws.com/v1/data-channel/robert-0xdeadbeef?role=publish_subscribe"
    },
    "requestID": "ac6ef216-4b33-dead-beef-9a1819f88c71",
    "eventID": "456edced-023f-dead-beef-2fb54a25fd38",
    "readOnly": false,
    "eventType": "AwsApiCall",
    "managementEvent": true,
    "eventCategory": "Management",
    "recipientAccountId": "123456789012"
}
```