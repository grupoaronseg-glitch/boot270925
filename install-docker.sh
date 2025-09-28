#!/bin/bash

# AutoClick Dashboard Docker Installation Script
# For users who prefer containerized deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
        elif [ -f /etc/arch-release ]; then
            OS="arch"
        else
            OS="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    print_status "Detected OS: $OS"
}

# Function to install Docker
install_docker() {
    if command_exists docker && command_exists docker-compose; then
        print_success "Docker and Docker Compose already installed"
        return
    fi

    print_status "Installing Docker and Docker Compose..."
    
    case $OS in
        "debian")
            # Update package index
            sudo apt-get update
            
            # Install prerequisites
            sudo apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker's official GPG key
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Set up stable repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker Engine
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            
            # Install Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "redhat")
            # Install Docker
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            
            # Install Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "arch")
            sudo pacman -S --noconfirm docker docker-compose
            ;;
        "macos")
            if command_exists brew; then
                brew install --cask docker
            else
                print_error "Please install Docker Desktop manually from https://docker.com"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported OS. Please install Docker manually."
            exit 1
            ;;
    esac
    
    # Add user to docker group (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo usermod -aG docker $USER
        print_warning "Please log out and log back in for Docker group changes to take effect"
    fi
    
    # Start Docker service
    if [[ "$OS" != "macos" ]]; then
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    print_success "Docker and Docker Compose installed successfully"
}

# Function to setup project
setup_project() {
    print_status "Setting up AutoClick Docker project..."
    
    PROJECT_DIR="$HOME/autoclick-dashboard"
    
    # Create project directory
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # Copy docker files (assuming they're in current directory)
    if [ -f "$(dirname "$0")/docker-compose.yml" ]; then
        cp "$(dirname "$0")/docker-compose.yml" .
        cp "$(dirname "$0")/nginx.conf" .
        cp -r "$(dirname "$0")/frontend" .
        cp -r "$(dirname "$0")/backend" .
    else
        print_error "Docker configuration files not found"
        exit 1
    fi
    
    # Create Dockerfiles
    cp "$(dirname "$0")/Dockerfile.backend" backend/Dockerfile
    cp "$(dirname "$0")/Dockerfile.frontend" frontend/Dockerfile
    
    # Create environment files
    cat > backend/.env << EOF
MONGO_URL=mongodb://mongodb:27017
DB_NAME=autoclick_db
ENVIRONMENT=production
EOF
    
    cat > frontend/.env << EOF
REACT_APP_BACKEND_URL=http://localhost:8001
EOF
    
    print_success "Project setup completed"
}

# Function to create control scripts
create_control_scripts() {
    print_status "Creating Docker control scripts..."
    
    # Start script
    cat > start-docker.sh << 'EOF'
#!/bin/bash
echo "Starting AutoClick Dashboard with Docker..."
docker-compose up -d
echo "Services started!"
echo "Frontend: http://localhost:3000"
echo "Backend:  http://localhost:8001"
echo "Nginx:    http://localhost:80"
EOF
    
    # Stop script
    cat > stop-docker.sh << 'EOF'
#!/bin/bash
echo "Stopping AutoClick Dashboard..."
docker-compose down
echo "Services stopped!"
EOF
    
    # Logs script
    cat > logs-docker.sh << 'EOF'
#!/bin/bash
echo "Showing logs for all services..."
docker-compose logs -f
EOF
    
    # Rebuild script
    cat > rebuild-docker.sh << 'EOF'
#!/bin/bash
echo "Rebuilding and restarting services..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d
echo "Services rebuilt and started!"
EOF
    
    chmod +x *.sh
    
    print_success "Control scripts created"
}

# Main function
main() {
    clear
    echo -e "${BLUE}"
    echo "============================================"
    echo "   AutoClick Dashboard Docker Installer"
    echo "============================================"
    echo -e "${NC}"
    echo
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_warning "This script should not be run as root for security reasons."
        print_warning "Please run as a regular user. The script will prompt for sudo when needed."
        exit 1
    fi
    
    # Detect OS
    detect_os
    
    if [[ "$OS" == "unknown" ]]; then
        print_error "Unsupported operating system. Please install Docker manually."
        exit 1
    fi
    
    print_status "Starting Docker installation process..."
    
    # Install Docker
    install_docker
    
    # Setup project
    setup_project
    
    # Create control scripts
    create_control_scripts
    
    # Final instructions
    echo
    echo -e "${GREEN}===========================================${NC}"
    echo -e "${GREEN}   Docker Installation Completed!${NC}"
    echo -e "${GREEN}===========================================${NC}"
    echo
    echo -e "${YELLOW}Project installed at:${NC} $HOME/autoclick-dashboard"
    echo
    echo -e "${YELLOW}To start with Docker:${NC}"
    echo "  cd $HOME/autoclick-dashboard"
    echo "  ./start-docker.sh"
    echo
    echo -e "${YELLOW}To stop:${NC}"
    echo "  ./stop-docker.sh"
    echo
    echo -e "${YELLOW}To view logs:${NC}"
    echo "  ./logs-docker.sh"
    echo
    echo -e "${YELLOW}To rebuild:${NC}"
    echo "  ./rebuild-docker.sh"
    echo
    echo -e "${YELLOW}Access URLs:${NC}"
    echo "  Main App: http://localhost (via Nginx)"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend:  http://localhost:8001"
    echo
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${YELLOW}Note:${NC} Please log out and log back in for Docker group changes to take effect"
        echo
    fi
    echo -e "${GREEN}Enjoy your containerized AutoClick Dashboard!${NC}"
    echo
}

# Run main function
main "$@"