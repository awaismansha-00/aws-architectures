resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*+-.:=?@_"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  identifier                 = "${var.name}-db"
  engine                     = "mysql"
  engine_version             = "8.4"
  instance_class             = var.db_instance_class
  allocated_storage          = 20
  storage_type               = "gp3"
  storage_encrypted          = true
  db_name                    = var.db_name
  username                   = "admin"
  password                   = random_password.db.result
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [var.db_security_group_id]
  publicly_accessible        = false
  backup_retention_period    = 1
  skip_final_snapshot        = true
  deletion_protection        = false
  auto_minor_version_upgrade = true
  apply_immediately          = true
  tags                       = var.tags
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.name}/db/credentials-${random_id.suffix.hex}"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db.result
    engine   = "mysql"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}
