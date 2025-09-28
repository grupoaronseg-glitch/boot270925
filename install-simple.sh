#!/bin/bash

# AutoClick Simple Installation Script
# No npm global packages - uses apt/yum only

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
echo -e "${BLUE}  AutoClick Simple Installer${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# Detect OS
if [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
else
    print_error "Unsupported OS. This script works on Debian/Ubuntu/Kali and RHEL/CentOS/Fedora"
    exit 1
fi

print_status "Detected OS: $OS"

# Install dependencies
print_status "Installing system dependencies..."

if [[ "$OS" == "debian" ]]; then
    # Update package list
    sudo apt-get update
    
    # Install core dependencies
    sudo apt-get install -y curl wget git build-essential python3 python3-pip python3-venv
    
    # Install Node.js via NodeSource
    print_status "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Install Yarn via official APT repository (no npm needed!)
    print_status "Installing Yarn via APT..."
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update
    sudo apt-get install -y yarn --no-install-recommends
    
    # Install MongoDB
    print_status "Installing MongoDB..."
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org
    
elif [[ "$OS" == "redhat" ]]; then
    # Install core dependencies
    sudo yum install -y curl wget git gcc gcc-c++ make python3 python3-pip
    
    # Install Node.js
    print_status "Installing Node.js..."
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
    
    # Install Yarn
    print_status "Installing Yarn..."
    curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
    sudo yum install -y yarn
    
    # Install MongoDB
    print_status "Installing MongoDB..."
    sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
    sudo yum install -y mongodb-org
fi

# Verify installations
print_status "Verifying installations..."
node --version && print_success "Node.js installed"
yarn --version && print_success "Yarn installed"
python3 --version && print_success "Python installed"
mongod --version && print_success "MongoDB installed"

# Setup project
PROJECT_DIR="$HOME/autoclick-dashboard"
MONGO_DATA_DIR="$HOME/mongodb-data"

print_status "Setting up project..."

# Create directories
mkdir -p "$PROJECT_DIR" "$MONGO_DATA_DIR"

# Copy project files (assuming script is in project root)
if [ -f "$(dirname "$0")/frontend/package.json" ]; then
    print_status "Copying project files..."
    cp -r "$(dirname "$0")"/* "$PROJECT_DIR/"
else
    print_error "Project files not found. Please run from project root."
    exit 1
fi

cd "$PROJECT_DIR"

# Setup backend
print_status "Setting up backend..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cd ..

# Setup frontend
print_status "Setting up frontend..."
cd frontend
yarn install
cd ..

# Create environment files
print_status "Creating configuration..."
cat > backend/.env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=autoclick_db
ENVIRONMENT=production
EOF

cat > frontend/.env << EOF
REACT_APP_BACKEND_URL=http://localhost:8001
EOF

# Create start script
cat > start.sh << 'EOF'
#!/bin/bash
echo "Starting AutoClick Dashboard..."

# Start MongoDB
if ! pgrep mongod > /dev/null; then
    echo "Starting MongoDB..."
    mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log
    sleep 2
fi

# Start backend
echo "Starting backend..."
cd backend
source venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8001 --reload &
BACKEND_PID=$!
cd ..

# Start frontend
echo "Starting frontend..."
cd frontend
yarn start &
FRONTEND_PID=$!
cd ..

echo "Services started!"
echo "Frontend: http://localhost:3000"
echo "Backend: http://localhost:8001"
echo "Press Ctrl+C to stop"

trap 'kill $BACKEND_PID $FRONTEND_PID; exit' INT
wait
EOF

chmod +x start.sh

# Create stop script
cat > stop.sh << 'EOF'
#!/bin/bash
echo "Stopping AutoClick Dashboard..."
pkill -f "uvicorn server:app"
pkill -f "react-scripts start"
echo "Stopped!"
EOF

chmod +x stop.sh

print_success "Installation completed!"
echo
echo -e "${YELLOW}To start AutoClick Dashboard:${NC}"
echo "  cd $PROJECT_DIR"
echo "  ./start.sh"
echo
echo -e "${YELLOW}Access:${NC}"
echo "  Frontend: http://localhost:3000"
echo "  Backend: http://localhost:8001"
echo
print_success "Setup complete! No npm permission issues!"