#!/bin/bash

# AutoClick Clean Installation Script
# Fixed version without escape character issues

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

clear
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  AutoClick Clean Installer${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Please run as regular user, not root!"
    exit 1
fi

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
    UPDATE_CMD="sudo apt-get update"
    INSTALL_CMD="sudo apt-get install -y"
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
    UPDATE_CMD="sudo yum update -y"
    INSTALL_CMD="sudo yum install -y"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="sudo dnf update -y"
    INSTALL_CMD="sudo dnf install -y"
else
    print_error "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

print_status "Detected package manager: $PKG_MANAGER"

# Update system
print_status "Updating system packages..."
$UPDATE_CMD

# Install basic dependencies
print_status "Installing basic dependencies..."
if [[ "$PKG_MANAGER" == "apt" ]]; then
    $INSTALL_CMD curl wget git build-essential python3 python3-pip python3-venv
elif [[ "$PKG_MANAGER" == "yum" || "$PKG_MANAGER" == "dnf" ]]; then
    $INSTALL_CMD curl wget git gcc gcc-c++ make python3 python3-pip
fi

# Install Node.js using NVM
print_status "Installing Node.js via NVM..."
if ! command -v node >/dev/null 2>&1; then
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    
    # Install Node.js 18
    nvm install 18
    nvm use 18
    nvm alias default 18
    
    # Add to bashrc
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"' >> ~/.bashrc
else
    print_success "Node.js already installed: $(node --version)"
fi

# Install Yarn
print_status "Installing Yarn..."
if ! command -v yarn >/dev/null 2>&1; then
    npm install -g yarn
fi

# Install Docker for MongoDB
print_status "Setting up Docker for MongoDB..."
if ! command -v docker >/dev/null 2>&1; then
    print_status "Installing Docker..."
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    elif [[ "$PKG_MANAGER" == "yum" ]]; then
        $INSTALL_CMD docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
    elif [[ "$PKG_MANAGER" == "dnf" ]]; then
        $INSTALL_CMD docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
    fi
    
    print_warning "Docker installed. You may need to log out and back in for group changes."
fi

# Setup project
PROJECT_DIR="$HOME/autoclick-dashboard"
MONGO_DATA_DIR="$HOME/mongodb-data"

print_status "Setting up project..."

# Create directories
mkdir -p "$PROJECT_DIR" "$MONGO_DATA_DIR"

# Copy project files
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
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

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

# Source NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Start MongoDB with Docker
if ! docker ps | grep autoclick-mongo > /dev/null; then
    echo "Starting MongoDB with Docker..."
    docker run -d --name autoclick-mongo -p 27017:27017 -v ~/mongodb-data:/data/db mongo:7.0 2>/dev/null || 
    docker start autoclick-mongo 2>/dev/null || {
        echo "Failed to start MongoDB with Docker. Trying alternative..."
        if command -v mongod >/dev/null 2>&1; then
            mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log
        else
            echo "WARNING: No MongoDB available. Backend may not work."
        fi
    }
    sleep 3
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

echo ""
echo "✅ Services started successfully!"
echo "📱 Frontend: http://localhost:3000"
echo "🔧 Backend:  http://localhost:8001"
echo "📊 API Docs: http://localhost:8001/docs"
echo ""
echo "Press Ctrl+C to stop all services"

trap 'echo "\nStopping services..."; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; docker stop autoclick-mongo 2>/dev/null || true; echo "Stopped!"; exit' INT
wait
EOF

chmod +x start.sh

# Create stop script
cat > stop.sh << 'EOF'
#!/bin/bash
echo "Stopping AutoClick Dashboard..."
pkill -f "uvicorn server:app" 2>/dev/null || true
pkill -f "react-scripts start" 2>/dev/null || true
docker stop autoclick-mongo 2>/dev/null || true
echo "✅ All services stopped!"
EOF

chmod +x stop.sh

# Create status script
cat > status.sh << 'EOF'
#!/bin/bash
echo "AutoClick Dashboard Status:"
echo "========================="

# Check MongoDB
if docker ps | grep autoclick-mongo > /dev/null; then
    echo "✅ MongoDB: Running (Docker)"
elif pgrep mongod > /dev/null; then
    echo "✅ MongoDB: Running (System)"
else
    echo "❌ MongoDB: Not running"
fi

# Check Backend
if curl -s http://localhost:8001/api/ > /dev/null 2>&1; then
    echo "✅ Backend: Running on port 8001"
else
    echo "❌ Backend: Not responding"
fi

# Check Frontend
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend: Running on port 3000"
else
    echo "❌ Frontend: Not responding"
fi

echo ""
echo "Access URLs:"
echo "Frontend: http://localhost:3000"
echo "Backend:  http://localhost:8001"
EOF

chmod +x status.sh

# Installation summary
print_success "Installation completed successfully!"
echo
echo -e "${YELLOW}=== INSTALLATION SUMMARY ===${NC}"
echo -e "Project location: ${BLUE}$PROJECT_DIR${NC}"
echo -e "MongoDB data:     ${BLUE}$MONGO_DATA_DIR${NC}"
echo
echo -e "${YELLOW}=== COMMANDS ===${NC}"
echo -e "Start:   ${GREEN}cd $PROJECT_DIR && ./start.sh${NC}"
echo -e "Stop:    ${GREEN}./stop.sh${NC}"
echo -e "Status:  ${GREEN}./status.sh${NC}"
echo
echo -e "${YELLOW}=== ACCESS URLS ===${NC}"
echo -e "Dashboard: ${GREEN}http://localhost:3000${NC}"
echo -e "API:       ${GREEN}http://localhost:8001${NC}"
echo -e "API Docs:  ${GREEN}http://localhost:8001/docs${NC}"
echo
if groups $USER | grep -q docker; then
    print_success "Ready to start! Run: cd $PROJECT_DIR && ./start.sh"
else
    print_warning "Please log out and back in for Docker permissions, then run: cd $PROJECT_DIR && ./start.sh"
fi
echo