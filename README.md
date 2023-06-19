# terraform-k8s-example

An example of a managed kubernetes deployment on AWS, Azure, and GCP using Terraform.

# Why deploy this way?
There are a number of reasons this strategy could be useful for your operations.

## Centralized Blueprints
Terraform scripts contain all the relevant details of how your cloud resources relate to one another and to the internet at large.
In the case of Kubernetes deployments, this can be extremely useful since that information is necessary in order to properly configure a manifest to run on a cluster.

## Turnkey Deployments
Terraform has the ability to provision entire cloud networks with one script. 
When combined with tools like Github Actions, you can deploy everything your team has designed with the click of a single button.

## Infrastructure Security
Because Terraform scripts can isolate the entire deployment process to a single step, 
there becomes only one set of credentials to manage for all of your infrastructure management.

# How can I use this repo?
This repo includes Terraform modules for provisioning a managed Kubernetes cluster on AWS Elastic Kubernetes Service, Azure Kubernetes Service, or Google Kubernetes Engine.
The actions are written with the assumption that the resources to be deployed are specified in a Kubernetes manifest file.
They could, however, easily be modified to install a Helm chart on the cluster since the actions are configured to use kubectl for the deployment step.

## With Kubernetes Manifest
The simplest way to deploy a set of resources to the clusters provisioned with these modules is to
describe your deployments, services, and other resources in a Kubernetes manifest file like the one provided as an example.
