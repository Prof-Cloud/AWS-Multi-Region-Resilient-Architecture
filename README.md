# AWS Multi-Region Disaster Recovery with Terraform and Aurora Global Database

In this project, I built a highly available, multi-region web application architecture on AWS that automatically survives regional failures. The application runs in 2 AWS regions and uses Aurora Global Database for data replication, Application Load Balancers and Auto Scaling Groups for compute resilience, and CloudWatch, SNS, Lambda to trigger automatic failover with the primary region goes down. 

<img width="761" height="853" alt="Screenshot 2026-02-03 at 4 15 53 PM" src="https://github.com/user-attachments/assets/e0844388-3ac1-4d69-81d5-43decfca643d" />


## What I Built

VPC and Networking 
  - Primary VPC in us-east-1 (Virginia)
  - Secondary VPC in eu-west-2 (London)
  - Public subnets for ALBs
  - Private subnets for EC2 application servers
  - Isolated database subnets for Aurora clusters
  - VPC endpoints for private S3 access without public internet

Application Load Balancer (ALB)
  - One ALB per region
  - Health checks usings /health
  - Route traffic to EC2 instances into Auto Scaling Groupss
  - Designed to receive traffic during regional failover seamlessly

Auto Scaling Groups (ASG)
  - EC2 instances running Amazon Linux 2023
  - PHP web application deployed via user data

Aurora Global Database  
- Aurora Global Database spans Virginia (writer) and London (reader)
- Continuous low-latency replication across regions
- Secrets stored securely in AWS Secrets Manager and replicated automatically 
