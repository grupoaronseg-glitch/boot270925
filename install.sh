#!/bin/bash

# AutoClick Installation Script
# Compatible with Ubuntu, Debian, Kali Linux, CentOS, Fedora

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project info
PROJECT_NAME="autoclick-dashboard"
REPO_URL="https://github.com/your-username/autoclick-dashboard.git" # You'll need to update this
INSTALL_DIR="$HOME/$PROJECT_NAME"
MONGO_DATA_DIR="$HOME/mongodb-data"

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

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
            if [ -f /etc/lsb-release ]; then
                . /etc/lsb-release
                if [[ "$DISTRIB_ID" == "Kali" ]]; then
                    OS="kali"
                fi
            fi
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Node.js
install_nodejs() {
    if command_exists node && command_exists npm; then
        NODE_VERSION=$(node --version)
        print_success "Node.js already installed: $NODE_VERSION"
        
        # Install yarn if not present
        if ! command_exists yarn; then
            print_status "Installing Yarn..."
            npm install -g yarn
        fi
        return
    fi

    print_status "Installing Node.js and npm..."
    
    case $OS in
        "debian"|"kali")
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        "redhat")
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo yum install -y nodejs npm
            ;;
        "arch")
            sudo pacman -S --noconfirm nodejs npm
            ;;
        "macos")
            if command_exists brew; then
                brew install node
            else
                print_error "Please install Node.js manually from https://nodejs.org/"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported OS. Please install Node.js manually."
            exit 1
            ;;
    esac
    
    # Install yarn
    print_status "Installing Yarn..."
    npm install -g yarn
    
    print_success "Node.js and Yarn installed successfully"
}

# Function to install Python
install_python() {
    if command_exists python3 && command_exists pip3; then
        PYTHON_VERSION=$(python3 --version)
        print_success "Python already installed: $PYTHON_VERSION"
        return
    fi

    print_status "Installing Python 3 and pip..."
    
    case $OS in
        "debian"|"kali")
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv
            ;;
        "redhat")
            sudo yum install -y python3 python3-pip
            ;;
        "arch")
            sudo pacman -S --noconfirm python python-pip
            ;;
        "macos")
            if command_exists brew; then
                brew install python3
            else
                print_error "Please install Python manually from https://python.org/"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported OS. Please install Python manually."
            exit 1
            ;;
    esac
    
    print_success "Python installed successfully"
}

# Function to install MongoDB
install_mongodb() {
    if command_exists mongod; then
        print_success "MongoDB already installed"
        return
    fi

    print_status "Installing MongoDB..."
    
    case $OS in
        "debian"|"kali")
            wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
            echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            sudo apt-get update
            sudo apt-get install -y mongodb-org
            ;;
        "redhat")
            sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
            sudo yum install -y mongodb-org
            ;;
        "arch")
            sudo pacman -S --noconfirm mongodb-bin
            ;;
        "macos")
            if command_exists brew; then
                brew tap mongodb/brew
                brew install mongodb-community
            else
                print_error "Please install MongoDB manually"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported OS. Please install MongoDB manually."
            exit 1
            ;;
    esac
    
    print_success "MongoDB installed successfully"
}

# Function to install Git
install_git() {
    if command_exists git; then
        print_success "Git already installed"
        return
    fi

    print_status "Installing Git..."
    
    case $OS in
        "debian"|"kali")
            sudo apt-get install -y git
            ;;
        "redhat")
            sudo yum install -y git
            ;;
        "arch")
            sudo pacman -S --noconfirm git
            ;;
        "macos")
            if command_exists brew; then
                brew install git
            else
                print_error "Please install Git manually"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported OS. Please install Git manually."
            exit 1
            ;;
    esac
    
    print_success "Git installed successfully"
}

# Function to setup MongoDB
setup_mongodb() {
    print_status "Setting up MongoDB..."
    
    # Create data directory
    mkdir -p "$MONGO_DATA_DIR"
    
    # Start MongoDB service if not running
    if ! pgrep -x "mongod" > /dev/null; then
        print_status "Starting MongoDB..."
        mongod --dbpath "$MONGO_DATA_DIR" --fork --logpath "$MONGO_DATA_DIR/mongodb.log"
        sleep 3
    fi
    
    print_success "MongoDB setup completed"
}

# Function to clone and setup project
setup_project() {
    print_status "Setting up AutoClick project..."
    
    # Remove existing directory if present
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone project (or copy current directory if running from source)
    if [ -f "$(dirname "$0")/package.json" ]; then
        print_status "Copying project from current directory..."
        cp -r "$(dirname "$0")" "$INSTALL_DIR"
    else
        print_status "Cloning project from repository..."
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi
    
    cd "$INSTALL_DIR"
    
    # Setup backend
    print_status "Setting up backend dependencies..."
    cd backend
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cd ..
    
    # Setup frontend
    print_status "Setting up frontend dependencies..."
    cd frontend
    yarn install
    cd ..
    
    # Create environment files
    create_env_files
    
    print_success "Project setup completed"
}

# Function to create environment files
create_env_files() {
    print_status "Creating environment configuration files..."
    
    # Backend .env
    cat > backend/.env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=autoclick_db
ENVIRONMENT=production
EOF
    
    # Frontend .env
    cat > frontend/.env << EOF
REACT_APP_BACKEND_URL=http://localhost:8001
EOF
    
    print_success "Environment files created"
}

# Function to create startup script
create_startup_script() {
    print_status "Creating startup script..."
    
    cat > "$INSTALL_DIR/start.sh" << 'EOF'
#!/bin/bash

# AutoClick Startup Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONGO_DATA_DIR="$HOME/mongodb-data"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting AutoClick Dashboard...${NC}"

# Start MongoDB if not running
if ! pgrep -x "mongod" > /dev/null; then
    echo -e "${YELLOW}Starting MongoDB...${NC}"
    mongod --dbpath "$MONGO_DATA_DIR" --fork --logpath "$MONGO_DATA_DIR/mongodb.log"
    sleep 3
fi

# Start backend
echo -e "${YELLOW}Starting backend server...${NC}"
cd "$PROJECT_DIR/backend"
source venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8001 --reload &
BACKEND_PID=$!

# Start frontend
echo -e "${YELLOW}Starting frontend server...${NC}"
cd "$PROJECT_DIR/frontend"
yarn start &
FRONTEND_PID=$!

# Save PIDs for cleanup
echo $BACKEND_PID > "$PROJECT_DIR/backend.pid"
echo $FRONTEND_PID > "$PROJECT_DIR/frontend.pid"

echo -e "${GREEN}AutoClick Dashboard started successfully!${NC}"
echo -e "${GREEN}Frontend: http://localhost:3000${NC}"
echo -e "${GREEN}Backend:  http://localhost:8001${NC}"
echo
echo "Press Ctrl+C to stop all services"

# Wait for Ctrl+C
trap 'kill $BACKEND_PID $FRONTEND_PID; exit' INT
wait
EOF
    
    chmod +x "$INSTALL_DIR/start.sh"
    
    # Create stop script
    cat > "$INSTALL_DIR/stop.sh" << 'EOF'
#!/bin/bash

# AutoClick Stop Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Stopping AutoClick Dashboard..."

# Kill frontend and backend
if [ -f "$PROJECT_DIR/frontend.pid" ]; then
    kill $(cat "$PROJECT_DIR/frontend.pid") 2>/dev/null
    rm "$PROJECT_DIR/frontend.pid"
fi

if [ -f "$PROJECT_DIR/backend.pid" ]; then
    kill $(cat "$PROJECT_DIR/backend.pid") 2>/dev/null
    rm "$PROJECT_DIR/backend.pid"
fi

# Kill any remaining processes
pkill -f "uvicorn server:app"
pkill -f "react-scripts start"

echo "AutoClick Dashboard stopped"
EOF
    
    chmod +x "$INSTALL_DIR/stop.sh"
    
    print_success "Startup scripts created"
}

# Function to create desktop shortcut (Linux)
create_desktop_shortcut() {
    if [[ "$OS" == "debian" || "$OS" == "kali" ]]; then
        print_status "Creating desktop shortcut..."
        
        DESKTOP_DIR="$HOME/Desktop"
        if [ ! -d "$DESKTOP_DIR" ]; then
            DESKTOP_DIR="$HOME/Área de Trabalho"  # Portuguese desktop
        fi
        
        if [ -d "$DESKTOP_DIR" ]; then
            cat > "$DESKTOP_DIR/AutoClick Dashboard.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=AutoClick Dashboard
Comment=Sistema de AutoClick para Sites
Exec=$INSTALL_DIR/start.sh
Icon=$INSTALL_DIR/icon.png
Terminal=true
StartupNotify=false
Categories=Utility;Development;
EOF
            chmod +x "$DESKTOP_DIR/AutoClick Dashboard.desktop"
            print_success "Desktop shortcut created"
        fi
    fi
}

# Main installation function
main() {
    clear
    echo -e "${BLUE}"
    echo "========================================"
    echo "    AutoClick Dashboard Installer"
    echo "========================================"
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
        print_error "Unsupported operating system. Please install dependencies manually."
        exit 1
    fi
    
    print_status "Starting installation process..."
    
    # Install dependencies
    install_git
    install_nodejs
    install_python
    install_mongodb
    
    # Setup MongoDB
    setup_mongodb
    
    # Setup project
    setup_project
    
    # Create startup scripts
    create_startup_script
    
    # Create desktop shortcut
    create_desktop_shortcut
    
    # Final instructions
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   Installation Completed Successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}Project installed at:${NC} $INSTALL_DIR"
    echo
    echo -e "${YELLOW}To start the application:${NC}"
    echo "  cd $INSTALL_DIR"
    echo "  ./start.sh"
    echo
    echo -e "${YELLOW}To stop the application:${NC}"
    echo "  ./stop.sh"
    echo
    echo -e "${YELLOW}Access URLs:${NC}"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend:  http://localhost:8001"
    echo
    echo -e "${YELLOW}MongoDB Data:${NC} $MONGO_DATA_DIR"
    echo
    echo -e "${GREEN}Enjoy your AutoClick Dashboard!${NC}"
    echo
}

# Run main function
main "$@"