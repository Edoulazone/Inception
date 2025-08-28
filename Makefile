# Project name
NAME = inception

# Path to Docker Compose file
COMPOSE_FILE = srcs/docker-compose.yml

# Data storage path on host
DATA_PATH = /home/$(USER)/data

# Default target (runs when you type 'make')
all: build up

# Build all Docker images
build:
	@echo "Building Docker images..."
	# Create data directories if they don't exist
	@mkdir -p $(DATA_PATH)/mysql $(DATA_PATH)/wordpress
	# Build all services defined in docker-compose.yml
	@cd srcs/ && docker-compose build

# Start all containers
up:
	@echo "Starting containers..."
	# Start containers in detached mode (-d)
	@cd srcs/ && docker-compose up

# Stop all containers
down:
	@echo "Stopping containers..."
	# Stop and remove containers
	@cd srcs/ && docker-compose down

# Clean up containers and images
clean: down
	@echo "Cleaning up..."
	# Remove unused containers, networks, images
	@docker system prune -af
	# Remove unused volumes
	@docker volume prune -f

# Full cleanup including data
fclean: clean
	@echo "Full cleanup..."
	# Remove data directories (WARNING: deletes all data!)
	@sudo rm -rf $(DATA_PATH)
	# Remove everything Docker-related
	@docker system prune -af --volumes

# Rebuild everything from scratch
re: fclean all

# Show container logs
logs:
	@timeout 30s docker-compose -f $(COMPOSE_FILE) logs -f || echo "Log viewing timed out"

# Show container status
status:
	@docker-compose -f $(COMPOSE_FILE) ps

# Declare phony targets (not actual files)
.PHONY: all build up down clean fclean re logs status