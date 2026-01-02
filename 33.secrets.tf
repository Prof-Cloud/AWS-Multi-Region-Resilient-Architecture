# Generate a random string for the password
resource "random_password" "db_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create the Secret container
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "vanish-db-master-password-v2"
  description = "Master password for Aurora Global Database"

  #Prevents "scheduled for deletion" lock in the future
  recovery_window_in_days = 0

  #Replicate the password to London automatically
  replica {
    region = "eu-west-2"
  }
}

# Store the random password in the Secret
resource "aws_secretsmanager_secret_version" "db_password_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = random_password.db_master_password.result
}