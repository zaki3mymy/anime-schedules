variable "appname" {
  type        = string
  description = "App name"
}
variable "annict_token" {
  type        = string
  description = "Token for calling Annict API"
}

variable "notify_api_key" {
  type        = string
  description = "API key for calling notification API"
}

variable "notify_endpoint" {
  type        = string
  description = "Endpoint URL of notification API"
}
