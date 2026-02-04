# AWS Multi-Region Disaster Recovery with Terraform and Aurora Global Database

In this project, I built a highly available, multi-region disaster recovery (DR) setup on AWS using Terraform. The goal of this project is to keep the application available even when an entire AWS region goes down without manual intervention. 

Traffic is served from the primary region (us-east-1). If the primary region becomes unhealthy, Route53 automatically fails over traffic to the secondary region (eu-west-2) using a combination of health checks and CloudWatch alarms.

This setup covers both the application layer and database layer, ensuring full end-to-end resilience. 


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

Lambda
- Triggered automatically when CloudWatch detects primary DB failure
- Uses "FailoverGlobalCluster" API to promote the London cluster
- Logs all actions to Cloudwatch for visibility and troubleshooting

SNS
- Sends email alerts when a database failover is triggered
- Notifies the developer when London becomes the new writer
- Real-time visibility into disaster recovery events

Cloudwatch
  
DNS Failover Strategy

Route53 is configured with failover routing policies for both: 
  - The root domain
  - The www subdomain

Each has:
  - A primary record pointing to the primary ALB
  - a secondary record pointing to the London ALB

If the primary region becomes unhealthy, Route53 automatically sends traffic to the secondary region. 

