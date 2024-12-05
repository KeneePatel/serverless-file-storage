# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnet in the first availability zone
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = [true]
  }
}

# S3 bucket for application versions
resource "aws_s3_bucket" "frontend_deployment" {
  bucket = "${var.project_name}-frontend-deployments"
  force_destroy = true
}

# Create ZIP file containing Dockerfile and application code
data "archive_file" "frontend" {
  type        = "zip"
  output_path = "${path.module}/frontend-deployment.zip"
  source_dir  = "../file-storage-frontend"
  excludes    = ["node_modules", ".next", ".git"]
}

# Upload ZIP to S3
resource "aws_s3_object" "frontend_app" {
  bucket = aws_s3_bucket.frontend_deployment.id
  key    = "frontend-${timestamp()}.zip"
  source = data.archive_file.frontend.output_path
  etag   = filemd5(data.archive_file.frontend.output_path)
}

# Create Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "frontend" {
  name        = "${var.project_name}-frontend"
  description = "Frontend application for file storage system"
}

# Create application version
resource "aws_elastic_beanstalk_application_version" "frontend_version" {
  name        = "frontend-${timestamp()}"
  application = aws_elastic_beanstalk_application.frontend.name
  description = "Frontend application version"
  bucket      = aws_s3_bucket.frontend_deployment.id
  key         = aws_s3_object.frontend_app.key
}

# Create Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "frontend_env" {
  name                = "${var.project_name}-frontend-${var.environment}"
  application         = aws_elastic_beanstalk_application.frontend.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.4.1 running Docker"
  version_label      = aws_elastic_beanstalk_application_version.frontend_version.name

  # IAM Settings
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "LabInstanceProfile"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "LabRole"
  }

  # VPC Settings
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", slice(data.aws_subnets.default.ids, 0, 1))
  }

  # Enhanced health reporting
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  # Application port
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "3000"
  }

  # Instance settings
  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "t2.medium"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "MonitoringInterval"
    value     = "1 minute"
  }

  # Environment type
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  # Health check settings
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"  # Change this to your health check endpoint if different
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "3000"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckTimeout"
    value     = "5"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckInterval"
    value     = "15"
  }

  # Log streaming to CloudWatch
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "7"
  }

  # Docker settings
  setting {
    namespace = "aws:elasticbeanstalk:environment:proxy"
    name      = "ProxyServer"
    value     = "nginx"
  }

  # Environment variables
  dynamic "setting" {
    for_each = {
      NEXT_PUBLIC_REGION = var.aws_region
      NEXT_PUBLIC_USER_POOL_ID = aws_cognito_user_pool.file_storage_pool.id
      NEXT_PUBLIC_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.file_storage_client.id
      NEXT_PUBLIC_API_URL = aws_api_gateway_stage.api_stage.invoke_url
    }
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }
}

# Output the environment URL
output "frontend_url" {
  value = aws_elastic_beanstalk_environment.frontend_env.endpoint_url
  description = "Frontend application URL"
}
