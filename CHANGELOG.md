## 0.3.3 (2018-01-30)

 - Allow full hierachy use of data across all environments

## 0.3.2 (2017-12-29)

 - Allow force when applying on Terraform versions >=0.11
 - Allow force apply and destroy on deployments on Terraform versions >=0.11

## 0.3.1 (2017-12-28)

 - Added a "deploy" command to allow deploying multiple projects in order as defined
 a "deployment" file

## 0.3.0 (2017-11-26)

 - Updated configuration file to allow default values and project specific values
 - Uses `-detailed-exitcode` by default, and warns user if there are changes pending
 - Small code tidy

## 0.2.4 (2017-10-15)

 - Updated cleaner method to check for both ".terraform" and "terraform.tfstate.backup"
 files, and not exit if they are not found.

