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

variable "otel_layer_arns" {
  type        = list(string)
  description = "ARNs of the OpenTelemetry Lambda layers (Python instrumentation + collector)"
}

variable "otel_instrumentations_layer_zip_path" {
  type        = string
  description = "Path to the zip of the Lambda layer with the OTel instrumentations missing from the community layer (built by scripts/build_otel_instrumentations_layer.py)"
}

variable "grafana_otlp_endpoint" {
  type        = string
  description = "OTLP endpoint of Grafana Cloud (the stack's OTLP URL with /otlp appended)"
}

variable "grafana_otlp_auth_parameter" {
  type        = string
  description = "Name of the SSM parameter that holds the Authorization header value for Grafana Cloud OTLP"
}

variable "memory_size" {
  type        = number
  description = "Memory size of the Lambda function in MB"
  default     = 256
}
