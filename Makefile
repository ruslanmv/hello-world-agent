# Makefile for the Hello World MCP Agent

.DEFAULT_GOAL := help

# --- Variables ---
PYTHON      := python3.11
VENV_NAME   := .venv
POETRY      := $(VENV_NAME)/bin/poetry
PID_FILE    := .pid
PORT        := 8000

# --- Phony Targets ---
.PHONY: all setup install start stop restart run-client clean help

# --- Main Targets ---

help: ## Display this help message
	@echo "Usage: make <command>"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Create the Python virtual environment
	@echo "--- Setting up virtual environment at $(VENV_NAME) ---"
	@if [ ! -d "$(VENV_NAME)" ]; then \
		$(PYTHON) -m venv $(VENV_NAME); \
		echo "--- Installing Poetry into the virtual environment ---"; \
		$(VENV_NAME)/bin/pip install --upgrade pip poetry; \
	else \
		echo "--- Virtual environment already exists. ---"; \
	fi
	@echo "--- Virtual environment is ready. ---"

install: setup ## Install all project dependencies
	@echo "--- Installing dependencies from pyproject.toml ---"
	@$(POETRY) install
	@echo "--- Dependencies installed. ---"

start: install ## Start the MCP agent server and wait for it to be ready
	@echo "--- Ensuring port $(PORT) is free by stopping any existing server... ---"
	@-lsof -t -i:$(PORT) | xargs kill -9 > /dev/null 2>&1
	@rm -f $(PID_FILE)
	@echo "--- Starting Hello World MCP server ---"
	@echo "--- Launching server in background... ---"
	@$(POETRY) run python agents/hello_world/hello_server.py &
	@echo "--- Waiting for server to become available on port $(PORT)... ---"
	@tries=0; \
	while ! lsof -i:$(PORT) -sTCP:LISTEN -t >/dev/null && [ $$tries -lt 20 ]; do \
		sleep 0.5; \
		tries=$$((tries + 1)); \
	done
	@if ! lsof -i:$(PORT) -sTCP:LISTEN -t >/dev/null; then \
		echo "--- ❌ Server failed to start. Check logs for errors. ---"; \
		exit 1; \
	fi
	@lsof -t -i:$(PORT) > $(PID_FILE)
	@echo "--- ✅ Server started with PID $$(cat $(PID_FILE)) on port $(PORT). ---"

stop: ## Stop the MCP agent server
	@echo "--- Stopping Hello World MCP server ---"
	@if [ -f $(PID_FILE) ]; then \
		echo "--- Stopping process with PID $$(cat $(PID_FILE))... ---"; \
		kill $$(cat $(PID_FILE)) 2>/dev/null || true; \
		rm -f $(PID_FILE); \
		echo "--- Server stopped via PID file. ---"; \
	else \
		echo "--- PID file not found. Searching for process on port $(PORT)... ---"; \
		pkill -f "hello_server.py" || lsof -t -i:$(PORT) | xargs kill -9 2>/dev/null || true; \
		echo "--- Attempted to stop server via port search. ---"; \
	fi
	@rm -f $(PID_FILE)

restart: ## Restart the MCP agent server
	@$(MAKE) stop
	@$(MAKE) start

run-client: install ## Run the simple async client
	@echo "--- Checking if server is running on port $(PORT) ---"
	@if ! lsof -i:$(PORT) -sTCP:LISTEN -t >/dev/null; then \
		echo "--- Server not running. Please run 'make start' first. ---"; \
		exit 1; \
	fi
	@echo "--- Running the simple async client ---"
	@$(POETRY) run python agents/hello_world/simple_client.py

clean: ## Remove the virtual environment, lock file, and build artifacts
	@echo "--- Cleaning up project 🧹 ---"
	@$(MAKE) stop > /dev/null 2>&1
	@rm -rf $(VENV_NAME)
	@rm -f $(PID_FILE) poetry.lock
	@echo "--- Cleanup complete. ---"