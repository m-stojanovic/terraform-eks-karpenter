# commented out to simplify the process of validating the task by OpsFleet team 
# data "terraform_remote_state" "main" {
#   backend = "s3"
#   config = {
#     bucket = "org-terraform-state"
#     key    = "project/dev/terraform.tfstate"
#     region = "us-east-1"
#   }
# }
