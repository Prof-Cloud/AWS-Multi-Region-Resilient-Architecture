# Primary Region Outputs (Virginia)
#To check if the app is actually running in primary region
output "primary_alb_dns_name" {
  description = "The DNS name of the primary Application Load Balancer"
  value       = aws_lb.primary_alb.dns_name
}

#The main database, writer endpoint
output "primary_aurora_endpoint" {
  description = "The writer endpoint for the primary Aurora cluster"
  value       = aws_rds_cluster.primary_cluster.endpoint
}

# Secondary Region Outputs (London)
# If primary region goes down, this is where everything is going to run from
output "secondary_alb_dns_name" {
  description = "The DNS name of the secondary Application Load Balancer"
  value       = aws_lb.secondary_alb_2nd.dns_name
}

# The Lodnon database, reader endpoint
output "secondary_aurora_reader_endpoint" {
  description = "The reader endpoint for the secondary Aurora cluster"
  value       = aws_rds_cluster.secondary_cluster.reader_endpoint
}

# Global / DNS Outputs
# The ID used to manage the link between Virginia and London.
output "global_db_id" {
  description = "The ID of the Aurora Global Database"
  value       = aws_rds_global_cluster.global_db.id
}

# AMI Outputs
# To verify the specific Amazon Linux 2023 version used in Virginia
output "primary_region_ami_id" {
  description = "The ID of the AMI used in the primary region (Virginia)"
  value       = data.aws_ami.linux_ami.id
}


# To verify the specific Amazon Linux 2023 version used in London
output "secondary_region_ami_id" {
  description = "The ID of the AMI used in the secondary region (London)"
  value       = data.aws_ami.linux_ami_2nd.id
}