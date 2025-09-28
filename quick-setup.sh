#!/bin/bash

# AutoClick Dashboard Quick Setup
# Minimal installation for immediate testing

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

clear
echo -e "${BLUE}"
echo "=================================="
echo "   AutoClick Quick Setup"
echo "==================================" 
echo -e "${NC}"
echo

print_status "This script will quickly setup AutoClick Dashboard for testing"
print_warning "For production use, please run the full install.sh script"
echo
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Quick dependency check
print_status "Checking dependencies..."

if ! command -v node >/dev/null 2>&1; then
    print_warning "Node.js not found. Installing..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

if ! command -v python3 >/dev/null 2>&1; then
    print_warning "Python not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv
fi

if ! command -v yarn >/dev/null 2>&1; then
    print_warning "Yarn not found. Installing..."
    npm install -g yarn
fi

# Quick MongoDB setup (using Docker if available)
if command -v docker >/dev/null 2>&1; then
    print_status "Starting MongoDB with Docker..."
    docker run -d --name autoclick-mongo -p 27017:27017 mongo:7.0 || true
else
    print_warning "Docker not found. Please install MongoDB manually or run full installer"
fi

# Setup project
print_status "Setting up project dependencies..."

# Frontend
cd frontend
print_status "Installing frontend dependencies..."
yarn install
cd ..

# Backend
cd backend
print_status "Setting up backend..."
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Create basic env files
print_status "Creating configuration files..."

cat > backend/.env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=autoclick_db
ENVIRONMENT=development
EOF

cat > frontend/.env << EOF
REACT_APP_BACKEND_URL=http://localhost:8001
EOF

# Create simple start script
cat > quick-start.sh << 'EOF'
#!/bin/bash
echo "Starting AutoClick Dashboard (Quick Mode)..."

# Start backend
cd backend
source venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8001 --reload &
BACKEND_PID=$!
cd ..

# Start frontend  
cd frontend
yarn start &
FRONTEND_PID=$!
cd ..

echo "Services started!"
echo "Frontend: http://localhost:3000"
echo "Backend:  http://localhost:8001"
echo "Press Ctrl+C to stop"

trap 'kill $BACKEND_PID $FRONTEND_PID; exit' INT
wait
EOF

chmod +x quick-start.sh

print_success "Quick setup completed!"
echo
print_status "To start the application:"
echo "  ./quick-start.sh"
echo
print_status "For full installation with all features:"
echo "  ./install.sh"
echo
print_warning "Note: This quick setup may not include all features"
print_warning "Use full installer for production environments"
