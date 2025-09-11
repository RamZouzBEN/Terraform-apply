provider "aws" {
  region = "eu-west-1"
}


data "aws_ami" "custom_ami" {
  most_recent      = true
  owners           = ["self"]
  filter {
    name   = "name"
    values = ["Windows*"]
  }
  filter {
    name   = "tag:BuildTime"
    values = ["20250909*"]
  }
}

data "aws_subnet" "selected" {
  filter {
    name   = "tag:Name"
    values = ["My-vault-vpc-subnet-private1-eu-west-1a"] # insert values here
  }
}

data "aws_security_group" "selected" {
  filter {
    name  = "tag:Name"
    values = ["Default"]
  }
}

data "aws_key_pair" "deployer" {
    key_name = "ec2-instances-2025"
}

data "aws_iam_instance_profile" "selected" {

   name   = "EC2InstanceProfile"

}


resource "aws_instance" "virtual_machine_test" {
  ami                         = data.aws_ami.custom_ami.id
  instance_type               = "m5.xlarge"
  key_name                    = data.aws_key_pair.deployer.key_name
  user_data                   = <<EOF
                        <powershell>
                          #########################Nommage des Instances EC2###############################################
                          $token = Invoke-RestMethod -Method Put -Uri http://169.254.169.254/latest/api/token -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"}
                          $instanceId = Invoke-RestMethod -Method Get -Uri http://169.254.169.254/latest/meta-data/instance-id -Headers @{"X-aws-ec2-metadata-token" = $token}
                          $env = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/tags/instance/ENV
                          $role = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/tags/instance/ROLE
                          $Prefix = "SC1A200"

                          If($ENV -eq "PROD") 
                              { 
                              $computername = $prefix + $role + "0" + $instanceId.Substring(16)
                              }
                          ElseIf($ENV -eq "INTE") 
                              { 
                                $computername = $prefix + $role + "I" + $instanceId.Substring(16)
                              }
                          Else
                              {
                              $computername = $prefix + $role + "D" + $instanceId.Substring(16)
                              }



                          Rename-Computer -NewName $ComputerName -ComputerName (hostname) -force
                          #############################Modification du Tag NAME###################################################

                          New-EC2Tag -Resource $InstanceID -Tag @{ Key = "Name"; Value = $ComputerName}

                          #############################DESACTIVATION DU FIREWALL##################################################

                          Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

                          #############################DESACTIVATION DE WINDOWS DEFENDER##########################################

                          Set-MpPreference -DisableRealtimeMonitoring $true

                          #############################Installation de Dynatrace#################################################
                          $url= aws ssm get-parameter --name /hr/dynatrace/windows/downloadUrl --with-decryption --query Parameter.Value --output text
                          $token= aws ssm get-parameter --name /hr/dynatrace/windows/token --with-decryption --query Parameter.Value --output text
                          set-location "c:\exploitation"
                          powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '$url' -Headers @{ 'Authorization' = 'Api-Token $token'} -OutFile 'c:\exploitation\Dynatrace-OneAgent-Windows.exe'"

                          start-process -filepath "c:\exploitation\Dynatrace-OneAgent-Windows.exe" -argumentlist "/qn --set-monitoring-mode=fullstack --set-app-log-content-access=true --set-network-zone=aws.dev-hrsprint --set-host-group=G_FRPA_P_FRPA_T_WAP_O_DED_FA_851P_C_WW --set-host-property=dt.security_context=G_FRPA_P_FRPA_T_WAP_O_DED_FA_851P_C_WW --set-host-property=dt.cost.costcenter=PAYROLL --set-host-id-source=fqdn --set-host-tag=AppName=HRSPRINT --set-host-tag=Service=HR-IIS --set-host-tag=Environment=FRPA" -wait

                          Get-service -name "*Dynatrace*" | stop-service -force

                          ##############################Restart Computer##########################################################

                          start-sleep 120

                          Restart-Computer
                        </powershell>
                        EOF
  subnet_id                   = data.aws_subnet.selected.id
  vpc_security_group_ids     = [data.aws_security_group.selected.id]
  associate_public_ip_address = false
  iam_instance_profile        = data.aws_iam_instance_profile.selected.name

  tags = merge(
      {"ENV" = "DEV"},
      {"ROLE" = "IIS"}
    )

  metadata_options {
    instance_metadata_tags      = "enabled"
  }
} 



