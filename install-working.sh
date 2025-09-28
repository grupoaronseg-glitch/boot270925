#!/bin/bash

# AutoClick Working Installation Script
# Creates complete project structure and scripts

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
echo -e "${BLUE}  AutoClick Working Installer${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Please run as regular user, not root!"
    exit 1
fi

# Get current directory (where project files are)
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$HOME/autoclick-dashboard"
MONGO_DATA_DIR="$HOME/mongodb-data"

print_status "Current directory: $CURRENT_DIR"
print_status "Will install to: $PROJECT_DIR"

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
    print_error "Unsupported package manager."
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

# Install Node.js
print_status "Installing Node.js..."
if ! command -v node >/dev/null 2>&1; then
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || {
            print_warning "NodeSource failed, trying default repository..."
            $INSTALL_CMD nodejs npm
        }
    elif [[ "$PKG_MANAGER" == "yum" || "$PKG_MANAGER" == "dnf" ]]; then
        $INSTALL_CMD nodejs npm
    fi
fi

# Install Yarn safely
print_status "Installing Yarn..."
if ! command -v yarn >/dev/null 2>&1; then
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        # Try corepack first (comes with Node.js 16+)
        if command -v corepack >/dev/null 2>&1; then
            corepack enable || true
        fi
        
        # If corepack doesn't work, try repository
        if ! command -v yarn >/dev/null 2>&1; then
            curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null 2>&1
            echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
            sudo apt-get update && sudo apt-get install -y yarn --no-install-recommends || {
                print_warning "Will use npx yarn instead of global installation"
            }
        fi
    elif [[ "$PKG_MANAGER" == "yum" || "$PKG_MANAGER" == "dnf" ]]; then
        $INSTALL_CMD yarn || {
            print_warning "Will use npx yarn instead"
        }
    fi
fi

# Install Docker
print_status "Installing Docker..."
if ! command -v docker >/dev/null 2>&1; then
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
fi

# Create project structure
print_status "Creating project structure..."

# Remove existing directory if present
if [ -d "$PROJECT_DIR" ]; then
    print_warning "Removing existing installation..."
    rm -rf "$PROJECT_DIR"
fi

# Create directories
mkdir -p "$PROJECT_DIR" "$MONGO_DATA_DIR"

# Check if we're running from the actual project directory
if [ -d "$CURRENT_DIR/frontend" ] && [ -d "$CURRENT_DIR/backend" ]; then
    print_status "Copying project files from current directory..."
    cp -r "$CURRENT_DIR"/* "$PROJECT_DIR/" 2>/dev/null || true
    cp -r "$CURRENT_DIR"/.[a-zA-Z]* "$PROJECT_DIR/" 2>/dev/null || true
else
    print_status "Creating project structure from scratch..."
    
    # Copy individual files that exist
    [ -f "$CURRENT_DIR/package.json" ] && cp "$CURRENT_DIR/package.json" "$PROJECT_DIR/"
    [ -f "$CURRENT_DIR/README.md" ] && cp "$CURRENT_DIR/README.md" "$PROJECT_DIR/"
    [ -f "$CURRENT_DIR/.gitignore" ] && cp "$CURRENT_DIR/.gitignore" "$PROJECT_DIR/"
    
    # Copy directories that exist
    [ -d "$CURRENT_DIR/frontend" ] && cp -r "$CURRENT_DIR/frontend" "$PROJECT_DIR/"
    [ -d "$CURRENT_DIR/backend" ] && cp -r "$CURRENT_DIR/backend" "$PROJECT_DIR/"
fi

cd "$PROJECT_DIR"

# Verify we have the necessary files
if [ ! -d "frontend" ] || [ ! -d "backend" ]; then
    print_error "Frontend or backend directory not found!"
    print_error "Please run this script from the project root directory that contains 'frontend' and 'backend' folders."
    exit 1
fi

# Setup backend
print_status "Setting up backend..."
cd backend
if [ ! -f "requirements.txt" ]; then
    print_error "requirements.txt not found in backend directory!"
    exit 1
fi

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cd ..

# Setup frontend
print_status "Setting up frontend..."
cd frontend
if [ ! -f "package.json" ]; then
    print_error "package.json not found in frontend directory!"
    exit 1
fi

# Use different yarn methods
if command -v yarn >/dev/null 2>&1; then
    print_status "Using system yarn..."
    yarn install
elif command -v corepack >/dev/null 2>&1 && corepack yarn --version >/dev/null 2>&1; then
    print_status "Using corepack yarn..."
    corepack yarn install
else
    print_status "Using npx yarn..."
    npx yarn install
fi

cd ..

# Create environment files
print_status "Creating environment files..."
cat > backend/.env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=autoclick_db
ENVIRONMENT=production
EOF

cat > frontend/.env << EOF
REACT_APP_BACKEND_URL=http://localhost:8001
EOF

# Create start script
print_status "Creating control scripts..."
cat > start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting AutoClick Dashboard..."

# Start MongoDB with Docker
if ! docker ps | grep autoclick-mongo > /dev/null; then
    echo "📦 Starting MongoDB with Docker..."
    docker run -d --name autoclick-mongo -p 27017:27017 -v ~/mongodb-data:/data/db mongo:7.0 2>/dev/null || 
    docker start autoclick-mongo 2>/dev/null || {
        echo "⚠️  Failed to start MongoDB with Docker. Trying system MongoDB..."
        if command -v mongod >/dev/null 2>&1; then
            mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log
        else
            echo "❌ No MongoDB available. Backend may not work properly."
        fi
    }
    sleep 3
fi

# Start backend
echo "🔧 Starting backend server..."
cd backend
source venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8001 --reload &
BACKEND_PID=$!
echo $BACKEND_PID > ../backend.pid
cd ..

# Start frontend
echo "🎨 Starting frontend server..."
cd frontend

# Use available yarn method
if command -v yarn >/dev/null 2>&1; then
    yarn start &
elif command -v corepack >/dev/null 2>&1 && corepack yarn --version >/dev/null 2>&1; then
    corepack yarn start &
else
    npx yarn start &
fi

FRONTEND_PID=$!
echo $FRONTEND_PID > ../frontend.pid
cd ..

echo ""
echo "✅ AutoClick Dashboard started successfully!"
echo ""
echo "📱 Frontend:  http://localhost:3000"
echo "🔧 Backend:   http://localhost:8001"
echo "📊 API Docs:  http://localhost:8001/docs"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for interrupt
trap 'echo ""; echo "🛑 Stopping services..."; kill $(cat backend.pid 2>/dev/null) 2>/dev/null; kill $(cat frontend.pid 2>/dev/null) 2>/dev/null; docker stop autoclick-mongo 2>/dev/null || true; rm -f backend.pid frontend.pid; echo "✅ Stopped!"; exit' INT
wait
EOF

chmod +x start.sh

# Create stop script
cat > stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping AutoClick Dashboard..."

# Stop processes using PIDs
if [ -f "backend.pid" ]; then
    kill $(cat backend.pid) 2>/dev/null
    rm -f backend.pid
fi

if [ -f "frontend.pid" ]; then
    kill $(cat frontend.pid) 2>/dev/null
    rm -f frontend.pid
fi

# Kill any remaining processes
pkill -f "uvicorn server:app" 2>/dev/null || true
pkill -f "react-scripts start" 2>/dev/null || true
pkill -f "webpack" 2>/dev/null || true

# Stop Docker container
docker stop autoclick-mongo 2>/dev/null || true

echo "✅ All services stopped!"
EOF

chmod +x stop.sh

# Create status script
cat > status.sh << 'EOF'
#!/bin/bash
echo "📊 AutoClick Dashboard Status"
echo "============================="

# Check environment
echo "Environment:"
if command -v node >/dev/null 2>&1; then
    echo "✅ Node.js: $(node --version)"
else
    echo "❌ Node.js: Not found"
fi

if command -v yarn >/dev/null 2>&1; then
    echo "✅ Yarn: $(yarn --version) (system)"
elif command -v corepack >/dev/null 2>&1 && corepack yarn --version >/dev/null 2>&1; then
    echo "✅ Yarn: $(corepack yarn --version) (corepack)"
else
    echo "⚠️  Yarn: Using npx (on-demand)"
fi

if command -v python3 >/dev/null 2>&1; then
    echo "✅ Python: $(python3 --version)"
else
    echo "❌ Python: Not found"
fi

if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
else
    echo "❌ Docker: Not found"
fi

echo ""

# Check services
echo "Services:"
if docker ps | grep autoclick-mongo > /dev/null; then
    echo "✅ MongoDB: Running (Docker)"
elif pgrep mongod > /dev/null; then
    echo "✅ MongoDB: Running (System)"
else
    echo "❌ MongoDB: Not running"
fi

if curl -s http://localhost:8001/api/ > /dev/null 2>&1; then
    echo "✅ Backend: Running on port 8001"
else
    echo "❌ Backend: Not responding"
fi

if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend: Running on port 3000"
else
    echo "❌ Frontend: Not responding"
fi

echo ""
echo "Access URLs:"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend:  http://localhost:8001"
echo "📚 API Docs: http://localhost:8001/docs"
EOF

chmod +x status.sh

# Create quick restart script
cat > restart.sh << 'EOF'
#!/bin/bash
echo "🔄 Restarting AutoClick Dashboard..."
./stop.sh
sleep 2
./start.sh
EOF

chmod +x restart.sh

# Installation summary
print_success "Installation completed successfully!"
echo
echo -e "${YELLOW}🎉 INSTALLATION SUMMARY${NC}"
echo "========================"
echo -e "📁 Project location: ${BLUE}$PROJECT_DIR${NC}"
echo -e "🗄️  MongoDB data:     ${BLUE}$MONGO_DATA_DIR${NC}"
echo
echo -e "${YELLOW}🛠️  AVAILABLE COMMANDS${NC}"
echo "===================="
echo -e "▶️  Start:    ${GREEN}cd $PROJECT_DIR && ./start.sh${NC}"
echo -e "⏹️  Stop:     ${GREEN}./stop.sh${NC}"
echo -e "📊 Status:   ${GREEN}./status.sh${NC}"
echo -e "🔄 Restart:  ${GREEN}./restart.sh${NC}"
echo
echo -e "${YELLOW}🌐 ACCESS URLS${NC}"
echo "=============="
echo -e "🎨 Dashboard: ${GREEN}http://localhost:3000${NC}"
echo -e "🔧 Backend:   ${GREEN}http://localhost:8001${NC}"
echo -e "📚 API Docs:  ${GREEN}http://localhost:8001/docs${NC}"
echo
echo -e "${YELLOW}📝 FILES CREATED${NC}"
echo "================"
echo "✅ start.sh - Start all services"
echo "✅ stop.sh - Stop all services"  
echo "✅ status.sh - Check service status"
echo "✅ restart.sh - Restart all services"
echo "✅ backend/.env - Backend configuration"
echo "✅ frontend/.env - Frontend configuration"
echo
if groups $USER | grep -q docker; then
    print_success "🚀 Ready to start! Run: cd $PROJECT_DIR && ./start.sh"
else
    print_warning "⚠️  Please log out and back in for Docker permissions to take effect"
    print_status "Then run: cd $PROJECT_DIR && ./start.sh"
fi
echo