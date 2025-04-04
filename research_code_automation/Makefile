.PHONY: setup install test lint format clean build docs run dev help venv checks update deploy docker docker-build docker-run

PYTHON := python3
PIP := pip3
VENV := venv
VENV_BIN := $(VENV)/bin
VENV_PYTHON := $(VENV_BIN)/python
VENV_PIP := $(VENV_BIN)/pip

help:
	@echo "Research Code Automation Tool"
	@echo ""
	@echo "Usage:"
	@echo "  make setup        Install development dependencies and set up environment"
	@echo "  make install      Install dependencies"
	@echo "  make dev          Install development dependencies"
	@echo "  make test         Run tests"
	@echo "  make lint         Run linters"
	@echo "  make format       Format code with black and isort"
	@echo "  make clean        Clean build artifacts"
	@echo "  make build        Build package"
	@echo "  make docs         Build documentation"
	@echo "  make run          Run the application (API server)"
	@echo "  make run-cli      Run the CLI"
	@echo "  make run-gui      Run the GUI"
	@echo "  make checks       Run pre-commit checks"
	@echo "  make update       Update dependencies"
	@echo "  make docker       Build and run Docker container"
	@echo "  make docker-build Build Docker image"
	@echo "  make docker-run   Run Docker container"
	@echo "  make help         Show this help message"

venv:
	$(PYTHON) -m venv $(VENV)
	@echo "Virtual environment created. Activate with: source $(VENV_BIN)/activate"

install: venv
	$(VENV_PIP) install -e .

dev: venv
	$(VENV_PIP) install -e ".[dev,complete]"
	$(VENV_PIP) install -r requirements-dev.txt
	$(VENV_PYTHON) -m pre_commit install

setup: venv
	$(VENV_PYTHON) setup_env.py --dev

test:
	$(VENV_PYTHON) -m pytest -xvs

test-cov:
	$(VENV_PYTHON) -m pytest --cov=research_code_automation --cov-report=xml --cov-report=term

lint:
	$(VENV_PYTHON) -m flake8 research_code_automation tests
	$(VENV_PYTHON) -m black --check research_code_automation tests
	$(VENV_PYTHON) -m isort --check-only research_code_automation tests
	$(VENV_PYTHON) -m mypy research_code_automation

format:
	$(VENV_PYTHON) -m black research_code_automation tests
	$(VENV_PYTHON) -m isort research_code_automation tests

checks:
	$(VENV_PYTHON) -m pre_commit run --all-files

clean:
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf .mypy_cache
	rm -rf __pycache__
	rm -rf research_code_automation/__pycache__
	rm -rf tests/__pycache__
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

build: clean
	$(VENV_PYTHON) -m pip install -U pip build
	$(VENV_PYTHON) -m build

docs:
	$(VENV_PYTHON) -m mkdocs build

serve-docs:
	$(VENV_PYTHON) -m mkdocs serve

update:
	$(VENV_PIP) install --upgrade pip setuptools wheel
	$(VENV_PIP) install --upgrade -r requirements.txt
	$(VENV_PIP) install --upgrade -r requirements-dev.txt

run:
	./run.sh --api

run-cli:
	./run.sh --cli

run-gui:
	./run.sh --gui

docker-build:
	docker build -t research-code-automation .

docker-run:
	docker run -p 8000:8000 research-code-automation

docker: docker-build docker-run

deploy:
	# Add your deployment commands here
	@echo "Deploying..."

# Default target
.DEFAULT_GOAL := help 