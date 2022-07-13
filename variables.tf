variable "endpoint" {
  type        = bool
  description = "Deny access to the public endpoint of the GKE cluster"
}
variable "img_version" {
  type        = string
  description = "It should start with composer-2*"
}
variable "airflow_config_overrides" {
  type = string
}
variable "cidr" {
  type = string
}
variable "project" {
  type = string
}
variable "keyring" {
  type = string
}
variable "keyname" {
  type = string
}
variable "sa" {
  type = string
}
variable "composer_name" {
  type=string
}
/*variable "access_token" {
  description = "access_token"
  type        = string
  sensitive   = true
}*/
