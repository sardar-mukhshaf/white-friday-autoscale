# ------------------------------------------------------------------------------
# White Friday Makefile
# Standardized commands for Terraform, Testing, and Chaos Engineering
# ------------------------------------------------------------------------------

.PHONY: help init plan apply destroy test chaos validate fmt lint

PROJECT_NAME ?= whitefriday
ENVIRONMENT ?= dev
REGION ?= eu-west-1
TF_DIR := terraform

help: ## Show this help message
	@echo "White Friday E-Commerce Auto-Scaling Platform"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform backend and modules
	@echo "Initializing Terraform for $(ENVIRONMENT)..."
	cd $(TF_DIR) && terraform init -backend-config="bucket=$(PROJECT_NAME)-terraform-state"

plan: ## Run Terraform plan for the specified environment
	@echo "Planning Terraform for $(ENVIRONMENT)..."
	cd $(TF_DIR) && terraform plan -var-file=environments/$(ENVIRONMENT).tfvars

apply: ## Apply Terraform changes for the specified environment
	@echo "Applying Terraform for $(ENVIRONMENT)..."
	cd $(TF_DIR) && terraform apply -var-file=environments/$(ENVIRONMENT).tfvars

destroy: ## Destroy Terraform infrastructure (USE WITH CAUTION)
	@echo "WARNING: This will DESTROY all resources in $(ENVIRONMENT)!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	cd $(TF_DIR) && terraform destroy -var-file=environments/$(ENVIRONMENT).tfvars

test: ## Run all unit tests for microservices
	@echo "Running unit tests..."
	cd kubernetes/microservices/frontend && npm ci && npm test || true
	cd ../product-service && npm ci && npm test || true
	cd ../cart-service && npm ci && npm test || true
	cd ../order-service && npm ci && npm test || true
	cd ../payment-service && npm ci && npm test || true

validate: ## Validate Terraform configuration
	@echo "Validating Terraform..."
	cd $(TF_DIR) && terraform validate
	cd $(TF_DIR) && terraform fmt -check=true -recursive

fmt: ## Format all Terraform and shell files
	@echo "Formatting code..."
	cd $(TF_DIR) && terraform fmt -recursive
	shellcheck scripts/*.sh || true

lint: ## Run tflint and checkov
	@echo "Running tflint..."
	cd $(TF_DIR) && tflint --recursive || true
	@echo "Running checkov..."
	checkov -d $(TF_DIR) --framework terraform || true

bootstrap: ## Bootstrap S3 backend and DynamoDB locks
	@echo "Bootstrapping backend..."
	bash scripts/bootstrap-backend.sh

preflight: ## Run pre-flight checks before deployment
	@echo "Running pre-flight checks..."
	bash scripts/pre-flight-checks.sh

load-test: ## Run k6 load tests against staging
	@echo "Running load tests..."
	bash scripts/run-load-test.sh

chaos: ## Run chaos engineering experiments in staging
	@echo "Running chaos experiments..."
	bash scripts/chaos-scheduler.sh

rollback: ## Trigger automated rollback on SLO breach
	@echo "Triggering rollback..."
	bash scripts/rollback.sh

docker-build: ## Build all microservices locally with docker-compose
	@echo "Building microservices..."
	cd kubernetes/microservices && docker-compose build

docker-up: ## Start all microservices locally
	@echo "Starting microservices..."
	cd kubernetes/microservices && docker-compose up -d

docker-down: ## Stop all local microservices
	@echo "Stopping microservices..."
	cd kubernetes/microservices && docker-compose down

k8s-deploy: ## Deploy Kubernetes manifests to the current context
	@echo "Deploying Kubernetes manifests..."
	kubectl apply -f kubernetes/karpenter/
	kubectl apply -f kubernetes/hpa/
	kubectl apply -f kubernetes/litmus/

k8s-destroy: ## Remove Kubernetes manifests
	@echo "Removing Kubernetes manifests..."
	kubectl delete -f kubernetes/karpenter/ --ignore-not-found=true
	kubectl delete -f kubernetes/hpa/ --ignore-not-found=true
	kubectl delete -f kubernetes/litmus/ --ignore-not-found=true
