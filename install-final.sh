#!/bin/bash

# AutoClick Final Installation Script
# Completely avoids npm global permission issues

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
echo -e "${BLUE}  AutoClick Final Installer${NC}"
echo -e "${BLUE}  (No npm permission issues)${NC}"
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

# Install Node.js using system packages (safer approach)
print_status "Installing Node.js..."
if ! command -v node >/dev/null 2>&1; then
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        # Install Node.js from NodeSource but with better error handling
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || {
            print_warning "NodeSource failed, trying snap..."
            sudo snap install node --classic || {
                print_warning "Snap failed, trying default repository..."
                $INSTALL_CMD nodejs npm
            }
        }
        if ! command -v node >/dev/null 2>&1; then
            $INSTALL_CMD nodejs npm
        fi
    elif [[ "$PKG_MANAGER" == "yum" || "$PKG_MANAGER" == "dnf" ]]; then
        $INSTALL_CMD nodejs npm
    fi
fi

# Alternative Yarn installation (no npm global needed)
print_status "Installing Yarn without npm global..."
if ! command -v yarn >/dev/null 2>&1; then
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        # Try official Yarn repository first
        print_status "Trying official Yarn repository..."
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null 2>&1 || true
        echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null 2>&1 || true
        sudo apt-get update 2>/dev/null && sudo apt-get install -y yarn --no-install-recommends 2>/dev/null || {
            print_warning "Yarn repository failed, using alternative method..."
            # Alternative: install yarn locally in project
            print_status "Will install yarn locally in project instead"
        }
    elif [[ "$PKG_MANAGER" == "yum" || "$PKG_MANAGER" == "dnf" ]]; then
        $INSTALL_CMD yarn || {
            print_warning "System yarn failed, will use alternative"
        }
    fi
fi

# Enable corepack if available (modern Node.js includes yarn via corepack)
if command -v corepack >/dev/null 2>&1; then
    print_status "Enabling corepack for yarn..."
    corepack enable || true
fi

# Setup Docker for MongoDB
print_status "Setting up Docker..."
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
fi

# Verify installations
print_status "Verifying installations..."
if command -v node >/dev/null 2>&1; then
    print_success "Node.js $(node --version) installed"
else
    print_error "Node.js installation failed"
    exit 1
fi

if command -v python3 >/dev/null 2>&1; then
    print_success "Python $(python3 --version) installed"
else
    print_error "Python installation failed"
    exit 1
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

# Setup frontend with yarn alternatives
print_status "Setting up frontend..."
cd frontend

# Try multiple yarn approaches
if command -v yarn >/dev/null 2>&1; then
    print_status "Using system yarn..."
    yarn install
elif command -v corepack >/dev/null 2>&1 && corepack yarn --version >/dev/null 2>&1; then
    print_status "Using corepack yarn..."
    corepack yarn install
else
    print_status "Using npx yarn (no global installation needed)..."
    npx yarn install
fi

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

# Create smart start script with yarn alternatives
cat > start.sh << 'EOF'
#!/bin/bash
echo "Starting AutoClick Dashboard..."

# Start MongoDB with Docker
if ! docker ps | grep autoclick-mongo > /dev/null; then
    echo "Starting MongoDB with Docker..."
    docker run -d --name autoclick-mongo -p 27017:27017 -v ~/mongodb-data:/data/db mongo:7.0 2>/dev/null || 
    docker start autoclick-mongo 2>/dev/null || {
        echo "Failed to start MongoDB with Docker. Trying system MongoDB..."
        if command -v mongod >/dev/null 2>&1; then
            mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log
        else
            echo "WARNING: No MongoDB available. Backend may not work properly."
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

# Start frontend with yarn alternatives
echo "Starting frontend..."
cd frontend

# Try different yarn commands
if command -v yarn >/dev/null 2>&1; then
    yarn start &
elif command -v corepack >/dev/null 2>&1 && corepack yarn --version >/dev/null 2>&1; then
    corepack yarn start &
else
    npx yarn start &
fi

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
pkill -f "webpack" 2>/dev/null || true
docker stop autoclick-mongo 2>/dev/null || true
echo "✅ All services stopped!"
EOF

chmod +x stop.sh

# Create status script
cat > status.sh << 'EOF'
#!/bin/bash
echo "AutoClick Dashboard Status:"
echo "========================="

# Check Node.js and Yarn
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

echo ""

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
echo -e "${YELLOW}=== YARN STATUS ===${NC}"
if command -v yarn >/dev/null 2>&1; then
    echo -e "Yarn method: ${GREEN}System installation${NC}"
elif command -v corepack >/dev/null 2>&1; then
    echo -e "Yarn method: ${GREEN}Corepack (built-in)${NC}"
else
    echo -e "Yarn method: ${YELLOW}NPX (on-demand)${NC}"
fi
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
print_success "Installation complete! No yarn permission issues!"
echo
print_status "Next steps:"
echo "1. cd $PROJECT_DIR"
echo "2. ./start.sh"
echo "3. Open http://localhost:3000 in your browser"
echo