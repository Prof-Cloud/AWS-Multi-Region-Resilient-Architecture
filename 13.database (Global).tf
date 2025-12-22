# Define the Global Cluster Hub
resource "aws_rds_global_cluster" "global_db" {
  global_cluster_identifier = "vanish-global-db"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.04.0"
  database_name             = "vanish_db"
  storage_encrypted         = true
}

# Primary Cluster (Virginia)
resource "aws_rds_cluster" "primary_cluster" {
  provider                  = aws # Default us-east-1
  cluster_identifier        = "vanish-primary-cluster"
  global_cluster_identifier = aws_rds_global_cluster.global_db.id
  engine                    = aws_rds_global_cluster.global_db.engine
  engine_version            = aws_rds_global_cluster.global_db.engine_version

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

# Credentials pulled from Secrets Manager
  master_password = aws_secretsmanager_secret_version.db_password_val.secret_string
  master_username = "admin"

# REQUIRED FOR DESTROY: Prevents the "FinalSnapshotIdentifier is required" error.
  # Set to 'false' in production to ensure you have a backup before deletion.
  skip_final_snapshot = true

  # Ensure primary is created before the secondary
  depends_on = [aws_rds_global_cluster.global_db]
}

# Secondary Cluster (London)
resource "aws_rds_cluster" "secondary_cluster" {
  provider                  = aws.London
  cluster_identifier        = "vanish-secondary-cluster"
  global_cluster_identifier = aws_rds_global_cluster.global_db.id
  engine                    = aws_rds_global_cluster.global_db.engine
  engine_version            = aws_rds_global_cluster.global_db.engine_version

# Credentials pulled from Secrets Manager
  db_subnet_group_name   = aws_db_subnet_group.aurora_2nd.name # You'll need this in London VPC
  vpc_security_group_ids = [aws_security_group.db_sg_2nd.id]

# REQUIRED FOR DESTROY: Prevents the "FinalSnapshotIdentifier is required" error.
  # Set to 'false' in production to ensure you have a backup before deletion.
  skip_final_snapshot = true

 #Moved from instance to cluste
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.london_rds_key.arn

  depends_on = [aws_rds_cluster.primary_cluster]
}

# 4. Instances for both regions
resource "aws_rds_cluster_instance" "primary_instances" {
  count              = 2
  identifier         = "vanish-db-primary-${count.index}"
  cluster_identifier = aws_rds_cluster.primary_cluster.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.primary_cluster.engine
}

resource "aws_rds_cluster_instance" "secondary_instances" {
  provider           = aws.London
  count              = 1 # Keep 1 instance in London to save cost until failover
  identifier         = "vanish-db-secondary-${count.index}"
  cluster_identifier = aws_rds_cluster.secondary_cluster.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.secondary_cluster.engine

  
  depends_on = [aws_rds_cluster.primary_cluster]
}

#Database Subnet
#Primary Regions
resource "aws_db_subnet_group" "aurora" {
  name       = "aurora-subnet-group"
  subnet_ids = aws_subnet.db_subnet[*].id
  tags       = { Name = "Main DB Subnet Group" }
}

#Secondary Regions
resource "aws_db_subnet_group" "aurora_2nd" {
  provider   = aws.London
  name       = "aurora-subnet-group-2nd"
  subnet_ids = aws_subnet.db_subnet_2nd[*].id
  tags       = { Name = "Secondary DB Subnet Group" }
}

# Create a KMS key in London
resource "aws_kms_key" "london_rds_key" {
  provider    = aws.London
  description = "KMS key for London RDS"
}