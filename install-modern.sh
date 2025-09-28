#!/bin/bash

# AutoClick Modern Installation Script
# Compatible with latest Ubuntu/Debian/Kali (no apt-key usage)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Please run as regular user, not root!"
    exit 1
fi

clear
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  AutoClick Modern Installer${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# Detect OS
if [ -f /etc/debian_version ]; then
    OS="debian"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "kali" ]]; then
            OS="kali"
        fi
    fi
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
else
    print_error "Unsupported OS. This script works on Debian/Ubuntu/Kali and RHEL/CentOS/Fedora"
    exit 1
fi

print_status "Detected OS: $OS"

# Install dependencies
print_status "Installing system dependencies..."

if [[ "$OS" == "debian" || "$OS" == "kali" ]]; then
    # Update package list
    sudo apt-get update
    
    # Install core dependencies
    print_status "Installing basic tools..."
    sudo apt-get install -y curl wget git build-essential software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    
    # Install Python
    print_status "Installing Python..."
    sudo apt-get install -y python3 python3-pip python3-venv python3-dev
    
    # Install Node.js via NodeSource (modern way)
    print_status "Installing Node.js..."
    if ! command -v node >/dev/null 2>&1; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -\n        sudo apt-get install -y nodejs\n    fi\n    \n    # Install Yarn via modern GPG method (no apt-key)\n    print_status \"Installing Yarn (modern method)...\"\n    if ! command -v yarn >/dev/null 2>&1; then\n        curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null\n        echo \"deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main\" | sudo tee /etc/apt/sources.list.d/yarn.list\n        sudo apt-get update\n        sudo apt-get install -y yarn\n    fi\n    \n    # Install MongoDB (modern method)\n    print_status \"Installing MongoDB (modern method)...\"\n    if ! command -v mongod >/dev/null 2>&1; then\n        curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-server-7.0.gpg >/dev/null\n        echo \"deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse\" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list\n        sudo apt-get update\n        sudo apt-get install -y mongodb-org\n    fi\n    \nelif [[ \"$OS\" == \"redhat\" ]]; then\n    # Install core dependencies\n    sudo yum install -y curl wget git gcc gcc-c++ make python3 python3-pip\n    \n    # Install Node.js\n    print_status \"Installing Node.js...\"\n    if ! command -v node >/dev/null 2>&1; then\n        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -\n        sudo yum install -y nodejs\n    fi\n    \n    # Install Yarn\n    print_status \"Installing Yarn...\"\n    if ! command -v yarn >/dev/null 2>&1; then\n        curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo\n        sudo yum install -y yarn\n    fi\n    \n    # Install MongoDB\n    print_status \"Installing MongoDB...\"\n    if ! command -v mongod >/dev/null 2>&1; then\n        sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF\n[mongodb-org-7.0]\nname=MongoDB Repository\nbaseurl=https://repo.mongodb.org/yum/redhat/\\$releasever/mongodb-org/7.0/x86_64/\ngpgcheck=1\nenabled=1\ngpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc\nEOF\n        sudo yum install -y mongodb-org\n    fi\nfi\n\n# Alternative MongoDB installation for systems that don't support official repos\nif ! command -v mongod >/dev/null 2>&1; then\n    print_warning \"Official MongoDB repo failed, trying alternative installation...\"\n    if [[ \"$OS\" == \"debian\" || \"$OS\" == \"kali\" ]]; then\n        # Try installing from default repos or use Docker\n        if command -v docker >/dev/null 2>&1; then\n            print_status \"Using MongoDB via Docker...\"\n            docker pull mongo:7.0 || true\n        else\n            print_status \"Installing MongoDB from default repository...\"\n            sudo apt-get install -y mongodb || print_warning \"MongoDB installation failed, will use Docker fallback\"\n        fi\n    fi\nfi\n\n# Verify installations\nprint_status \"Verifying installations...\"\nif command -v node >/dev/null 2>&1; then\n    print_success \"Node.js $(node --version) installed\"\nelse\n    print_error \"Node.js installation failed\"\n    exit 1\nfi\n\nif command -v yarn >/dev/null 2>&1; then\n    print_success \"Yarn $(yarn --version) installed\"\nelse\n    print_error \"Yarn installation failed\"\n    exit 1\nfi\n\nif command -v python3 >/dev/null 2>&1; then\n    print_success \"Python $(python3 --version) installed\"\nelse\n    print_error \"Python installation failed\"\n    exit 1\nfi\n\n# Setup project\nPROJECT_DIR=\"$HOME/autoclick-dashboard\"\nMONGO_DATA_DIR=\"$HOME/mongodb-data\"\n\nprint_status \"Setting up project...\"\n\n# Create directories\nmkdir -p \"$PROJECT_DIR\" \"$MONGO_DATA_DIR\"\n\n# Copy project files (assuming script is in project root)\nif [ -f \"$(dirname \"$0\")/frontend/package.json\" ]; then\n    print_status \"Copying project files...\"\n    cp -r \"$(dirname \"$0\")\"/* \"$PROJECT_DIR/\"\nelse\n    print_error \"Project files not found. Please run from project root.\"\n    exit 1\nfi\n\ncd \"$PROJECT_DIR\"\n\n# Setup backend\nprint_status \"Setting up backend...\"\ncd backend\npython3 -m venv venv\nsource venv/bin/activate\npip install --upgrade pip\npip install -r requirements.txt\ncd ..\n\n# Setup frontend\nprint_status \"Setting up frontend...\"\ncd frontend\nyarn install\ncd ..\n\n# Create environment files\nprint_status \"Creating configuration...\"\ncat > backend/.env << EOF\nMONGO_URL=mongodb://localhost:27017\nDB_NAME=autoclick_db\nENVIRONMENT=production\nEOF\n\ncat > frontend/.env << EOF\nREACT_APP_BACKEND_URL=http://localhost:8001\nEOF\n\n# Create start script with MongoDB options\ncat > start.sh << 'EOF'\n#!/bin/bash\necho \"Starting AutoClick Dashboard...\"\n\n# Start MongoDB (multiple options)\nif ! pgrep mongod > /dev/null; then\n    echo \"Starting MongoDB...\"\n    \n    # Try system MongoDB first\n    if command -v mongod >/dev/null 2>&1; then\n        mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log\n        sleep 2\n    # Fallback to Docker if available\n    elif command -v docker >/dev/null 2>&1; then\n        echo \"Using MongoDB via Docker...\"\n        docker run -d --name autoclick-mongo -p 27017:27017 -v ~/mongodb-data:/data/db mongo:7.0 || \n        docker start autoclick-mongo || true\n        sleep 3\n    else\n        echo \"WARNING: MongoDB not found. Backend may not work properly.\"\n    fi\nfi\n\n# Start backend\necho \"Starting backend...\"\ncd backend\nsource venv/bin/activate\nuvicorn server:app --host 0.0.0.0 --port 8001 --reload &\nBACKEND_PID=$!\ncd ..\n\n# Start frontend\necho \"Starting frontend...\"\ncd frontend\nyarn start &\nFRONTEND_PID=$!\ncd ..\n\necho \"Services started!\"\necho \"Frontend: http://localhost:3000\"\necho \"Backend: http://localhost:8001\"\necho \"Press Ctrl+C to stop\"\n\ntrap 'kill $BACKEND_PID $FRONTEND_PID; docker stop autoclick-mongo 2>/dev/null || true; exit' INT\nwait\nEOF\n\nchmod +x start.sh\n\n# Create stop script\ncat > stop.sh << 'EOF'\n#!/bin/bash\necho \"Stopping AutoClick Dashboard...\"\npkill -f \"uvicorn server:app\" || true\npkill -f \"react-scripts start\" || true\ndocker stop autoclick-mongo 2>/dev/null || true\necho \"Stopped!\"\nEOF\n\nchmod +x stop.sh\n\n# Create MongoDB status check script\ncat > check-mongo.sh << 'EOF'\n#!/bin/bash\necho \"Checking MongoDB status...\"\n\nif pgrep mongod > /dev/null; then\n    echo \"✅ MongoDB is running (system)\"\nelif docker ps | grep autoclick-mongo > /dev/null; then\n    echo \"✅ MongoDB is running (Docker)\"\nelse\n    echo \"❌ MongoDB is not running\"\n    echo \"To start MongoDB:\"\n    echo \"  System: mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log\"\n    echo \"  Docker: docker run -d --name autoclick-mongo -p 27017:27017 mongo:7.0\"\nfi\nEOF\n\nchmod +x check-mongo.sh\n\nprint_success \"Installation completed!\"\necho\necho -e \"${YELLOW}To start AutoClick Dashboard:${NC}\"\necho \"  cd $PROJECT_DIR\"\necho \"  ./start.sh\"\necho\necho -e \"${YELLOW}To check MongoDB status:${NC}\"\necho \"  ./check-mongo.sh\"\necho\necho -e \"${YELLOW}Access:${NC}\"\necho \"  Frontend: http://localhost:3000\"\necho \"  Backend: http://localhost:8001\"\necho\nprint_success \"Modern installation complete - no apt-key issues!\""