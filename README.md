## AWS Multi-Region Disaster Recovery with Terraform and Aurora Global Database

In this project, I built a highly available, multi-region web application architecture on AWS that automatically survives regional failures. The application runs in 2 AWS regions and uses Aurora Global Database for data replication, Application Load Balancers and Auto Scaling Groups for compute resilience, and CloudWatch, SNS, Lambda to trigger automatic failover with the primary region goes down. 
