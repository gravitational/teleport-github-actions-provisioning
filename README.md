# Secure provisioning of Teleport targets with Github Actions

This repository is an example of using Teleport Machine ID with Github Actions, to securely provision Teleport targets. It includes the Actions workflow, as well as some example Terraform code for provisioning a server to AWS. 

By running this workflow, you can provision a server which will automatically join itself to your Teleport cluster, without any hardcoded secrets. After 10 minutes this server will then be removed from the cluster and your AWS account.

## Why?

Teleport supports many methods for secure auto-joining of distributed services. For example:
- Node auto-join via AWS IAM Role ([docs](https://goteleport.com/docs/management/guides/joining-nodes-aws-iam/))
- Node auto-join via AWS EC2 ([docs](https://goteleport.com/docs/management/guides/joining-nodes-aws-ec2/))
- Node auto-join and discovery for Azure (docs)
- Kubernetes discovery for EKS, GKE and AKS ([docs](https://goteleport.com/docs/kubernetes-access/discovery/))
- RDS Database discovery ([docs](https://goteleport.com/docs/database-access/guides/rds/))


However, not every platform or use-case is covered by the existing auto-join solutions. For example, if you are deploying Teleport services on-prem, there is no existing trust mechanism that Teleport can integrate with for secure auto-join. 

In this case, Teleport supports the generation of short-lived tokens which can be used for the initial service join. An example of how to do this is [here](https://goteleport.com/docs/management/admin/adding-nodes/). 

The challenge with this process is that it has historically been hard to automate in a secure way. How do I give a CICD pipeline the ability to generate short-lived tokens without hard-coding a long-lived credential in the pipeline itself?

## Introducing Machine ID

Machine ID was introduced in Teleport 10 as a way of opening up the Teleport workflow beyond users. It gives you a way of solving connectivity, authentication, authorization and audit for services and applications. 
(A great primer on Machine ID is [here](https://www.youtube.com/watch?v=QWd0eqIa9mA&ab_channel=Teleport).)

As Machine ID has matured, we have added support for various CICD platforms, starting with Github Actions. 

You can see a guide for providing connectivity to an SSH host using Teleport and Github Actions [here](https://goteleport.com/docs/machine-id/guides/github-actions/). 

The great thing about Machine ID is that it can helpe with use cases outside of securely connecting to infrastructure. In fact it can help with administrative actions against Teleport itself, including the ability to generate short-lived tokens! 

## Using this repository

### Pre-requisites
* An existing Teleport cluster or Teleport Cloud instance. See a getting started guide for a self-hosted cluster [here](https://goteleport.com/docs/try-out-teleport/linux-server/). You will need the publically available DNS address of your Teleport service as an input for this action. 
* A Github Personal Access Token (with repository read/write permissions).
* AWS Credentials for Terraform provisioning (If you plan to run the Terraform step in this workflow)

### Teleport Configuration
1. Create a Github token in Teleport, explicitly naming the repository where you will run this action. This will enable trust between the repository and your Teleport cluster. An example token definition is in `teleport/gha_token.yaml`. Apply this file to your cluster using `tctl create -f gha_token.yaml`. 
2. Create a role for your Machine ID bot. This bot should have permissions to only manage tokens and nothing else. An example of a role with these privileges is at `teleport/gha_bot_role.yaml`. Apply the role to your cluster using `tctl create -f gha_bot_role.yaml`
3. Create the Machine ID bot. This will link a bot user to the role and token we just created. `tctl bots add gha-token-bot --roles=<match your role name> --token=<match your token name>`

### Github Actions Configuration
1. The example workflow at `.github/workflows/main.yaml` requires four secrets to run. 
   * PAT:  A github Personal Access Token which will give the workflow permissions to check out your repository.
   * AWS_ACCESS_KEY_ID
   * AWS_SECRET_ACCESS_KEY
   * AWS_SESSION_TOKEN
     * These are one way for Terraform to authenticate to AWS. You may have other ways of authenticating as per the [Terraform AWS documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#provider-configuration)

### Terraform configuration
1. The terraform configuration is located in the `terraform` folder. It contains code to create an EC2 server running Ubuntu (see `target_node.tf` for exact version), and all the supporting infrastructure for that server to connect to your Teleport instance. 
2. Take a look at `target_node.tf` to understand how Teleport is configured and how the token is passed into the Teleport configuration. 
3. Five variables are required for the Terraform code to work. An example of fulfilling these variables is in `terraform/terraform.tfvars.example`. When you have satisfied these variables, save the file as `terraform/terraform.tfvars` so they are picked up during the Terraform run. 
```
region = "us-west-2"
proxy_server = "my.teleportproxy.net:443"
key_name = "my-ssh-key"
hostname = "my-hostname"
teleport_version = "12.1.1"
```
Note that the `key_name` refers to an SSH key that is for troubleshooting only. This is not used by Teleport, but may be useful for investigating issues such as the node not joining your server. Teleport best practices recommends not leveraging static SSH keys for day-to-day access to any server, but if you need to troubleshoot issues outside of Teleport then having secondary access is needed.

The Teleport version should ideally match your cluster version. 

### Activating the workflow
Currently the workflow will execute on any commit to main. Once you have satisfied the pre-requisites and the above steps, the workflow should create an SSH target which joins your cluster, and then is removed 10 minutes later. 

## Questions or comments?
Please feel free to raise an issue on this repository!