.PHONY: help
help:  ## Print the help documentation
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check: fmt lint  ## Terraform fmt and lint check
lint: lint  ## Lint terraform

.PHONY: check
fmt:  ## Terraform fmt check
	terraform fmt -check

.PHONY: check
lint:  ## Terraform lint
	tflint --init
	tflint
