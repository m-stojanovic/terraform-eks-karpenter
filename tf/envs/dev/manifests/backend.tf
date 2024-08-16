# terraform {
#   backend "s3" {
#     region               = "us-east-1"                          
#     bucket               = "org-terraform-state"   
#     key                  = "project/dev/manifests/terraform.tfstate"                    
#     dynamodb_table       = "org-terraform-state-locks"          
#   }
# }