#!/bin/bash

# AutoClick Safe Installation Script
# Works on any Linux system - no external repos needed

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
echo -e "${BLUE}  AutoClick Safe Installer${NC}"
echo -e "${BLUE}  (Works on any Linux system)${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Please run as regular user, not root!"
    exit 1
fi

# Detect OS
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
elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
    UPDATE_CMD="sudo pacman -Sy"
    INSTALL_CMD="sudo pacman -S --noconfirm"
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
elif [[ "$PKG_MANAGER" == "pacman" ]]; then
    $INSTALL_CMD curl wget git base-devel python python-pip


# Install Node.js using Node Version Manager (no external repos needed)
print_status "Installing Node.js via NVM..."
if ! command -v node >/dev/null 2>&1; then\n    # Install NVM\n    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash\n    \n    # Source NVM\n    export NVM_DIR=\"$HOME/.nvm\"\n    [ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\"\n    [ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\"\n    \n    # Install Node.js 18\n    nvm install 18\n    nvm use 18\n    nvm alias default 18\n    \n    # Add to bashrc for permanent use\n    echo 'export NVM_DIR=\"$HOME/.nvm\"' >> ~/.bashrc\n    echo '[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\"' >> ~/.bashrc\n    echo '[ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\"' >> ~/.bashrc\nelse\n    print_success \"Node.js already installed: $(node --version)\"\nfi\n\n# Install Yarn using npm (now that we have Node.js in user space)\nprint_status \"Installing Yarn...\"\nif ! command -v yarn >/dev/null 2>&1; then\n    npm install -g yarn\nfi\n\n# Install MongoDB using Docker (safest method)\nprint_status \"Setting up MongoDB...\"\nif ! command -v docker >/dev/null 2>&1; then\n    print_status \"Installing Docker...\"\n    if [[ \"$PKG_MANAGER\" == \"apt\" ]]; then\n        # Install Docker via convenience script\n        curl -fsSL https://get.docker.com -o get-docker.sh\n        sudo sh get-docker.sh\n        sudo usermod -aG docker $USER\n        rm get-docker.sh\n    elif [[ \"$PKG_MANAGER\" == \"yum\" ]]; then\n        $INSTALL_CMD docker\n        sudo systemctl start docker\n        sudo systemctl enable docker\n        sudo usermod -aG docker $USER\n    elif [[ \"$PKG_MANAGER\" == \"dnf\" ]]; then\n        $INSTALL_CMD docker\n        sudo systemctl start docker\n        sudo systemctl enable docker\n        sudo usermod -aG docker $USER\n    elif [[ \"$PKG_MANAGER\" == \"pacman\" ]]; then\n        $INSTALL_CMD docker\n        sudo systemctl start docker\n        sudo systemctl enable docker\n        sudo usermod -aG docker $USER\n    fi\n    \n    print_warning \"Docker installed. You may need to log out and back in for group changes to take effect.\"\nfi\n\n# Setup project\nPROJECT_DIR=\"$HOME/autoclick-dashboard\"\nMONGO_DATA_DIR=\"$HOME/mongodb-data\"\n\nprint_status \"Setting up project...\"\n\n# Create directories\nmkdir -p \"$PROJECT_DIR\" \"$MONGO_DATA_DIR\"\n\n# Copy project files\nif [ -f \"$(dirname \"$0\")/frontend/package.json\" ]; then\n    print_status \"Copying project files...\"\n    cp -r \"$(dirname \"$0\")\"/* \"$PROJECT_DIR/\"\nelse\n    print_error \"Project files not found. Please run from project root.\"\n    exit 1\nfi\n\ncd \"$PROJECT_DIR\"\n\n# Setup backend\nprint_status \"Setting up backend...\"\ncd backend\npython3 -m venv venv\nsource venv/bin/activate\npip install --upgrade pip\npip install -r requirements.txt\ncd ..\n\n# Setup frontend (source NVM first)\nprint_status \"Setting up frontend...\"\nexport NVM_DIR=\"$HOME/.nvm\"\n[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\"\n\ncd frontend\nyarn install\ncd ..\n\n# Create environment files\nprint_status \"Creating configuration...\"\ncat > backend/.env << EOF\nMONGO_URL=mongodb://localhost:27017\nDB_NAME=autoclick_db\nENVIRONMENT=production\nEOF\n\ncat > frontend/.env << EOF\nREACT_APP_BACKEND_URL=http://localhost:8001\nEOF\n\n# Create comprehensive start script\ncat > start.sh << 'EOF'\n#!/bin/bash\necho \"Starting AutoClick Dashboard...\"\n\n# Source NVM for Node.js/Yarn\nexport NVM_DIR=\"$HOME/.nvm\"\n[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\"\n\n# Start MongoDB with Docker\nif ! docker ps | grep autoclick-mongo > /dev/null; then\n    echo \"Starting MongoDB with Docker...\"\n    docker run -d --name autoclick-mongo -p 27017:27017 -v ~/mongodb-data:/data/db mongo:7.0 2>/dev/null || \n    docker start autoclick-mongo 2>/dev/null || {\n        echo \"Failed to start MongoDB with Docker. Trying alternative...\"\n        if command -v mongod >/dev/null 2>&1; then\n            mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log\n        else\n            echo \"WARNING: No MongoDB available. Backend may not work.\"\n        fi\n    }\n    sleep 3\nfi\n\n# Start backend\necho \"Starting backend...\"\ncd backend\nsource venv/bin/activate\nuvicorn server:app --host 0.0.0.0 --port 8001 --reload &\nBACKEND_PID=$!\ncd ..\n\n# Start frontend\necho \"Starting frontend...\"\ncd frontend\nyarn start &\nFRONTEND_PID=$!\ncd ..\n\necho \"\"\necho \"✅ Services started successfully!\"\necho \"📱 Frontend: http://localhost:3000\"\necho \"🔧 Backend:  http://localhost:8001\"\necho \"📊 API Docs: http://localhost:8001/docs\"\necho \"\"\necho \"Press Ctrl+C to stop all services\"\n\ntrap 'echo \"\\nStopping services...\"; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; docker stop autoclick-mongo 2>/dev/null || true; echo \"Stopped!\"; exit' INT\nwait\nEOF\n\nchmod +x start.sh\n\n# Create stop script\ncat > stop.sh << 'EOF'\n#!/bin/bash\necho \"Stopping AutoClick Dashboard...\"\npkill -f \"uvicorn server:app\" 2>/dev/null || true\npkill -f \"react-scripts start\" 2>/dev/null || true\ndocker stop autoclick-mongo 2>/dev/null || true\necho \"✅ All services stopped!\"\nEOF\n\nchmod +x stop.sh\n\n# Create status check script\ncat > status.sh << 'EOF'\n#!/bin/bash\necho \"AutoClick Dashboard Status:\"\necho \"=========================\"\n\n# Check MongoDB\nif docker ps | grep autoclick-mongo > /dev/null; then\n    echo \"✅ MongoDB: Running (Docker)\"\nelif pgrep mongod > /dev/null; then\n    echo \"✅ MongoDB: Running (System)\"\nelse\n    echo \"❌ MongoDB: Not running\"\nfi\n\n# Check Backend\nif curl -s http://localhost:8001/api/ > /dev/null 2>&1; then\n    echo \"✅ Backend: Running on port 8001\"\nelse\n    echo \"❌ Backend: Not responding\"\nfi\n\n# Check Frontend\nif curl -s http://localhost:3000 > /dev/null 2>&1; then\n    echo \"✅ Frontend: Running on port 3000\"\nelse\n    echo \"❌ Frontend: Not responding\"\nfi\n\necho \"\"\necho \"Access URLs:\"\necho \"Frontend: http://localhost:3000\"\necho \"Backend:  http://localhost:8001\"\nEOF\n\nchmod +x status.sh\n\n# Create installation summary\nprint_success \"Installation completed successfully!\"\necho\necho -e \"${YELLOW}=== INSTALLATION SUMMARY ===${NC}\"\necho -e \"Project location: ${BLUE}$PROJECT_DIR${NC}\"\necho -e \"MongoDB data:     ${BLUE}$MONGO_DATA_DIR${NC}\"\necho\necho -e \"${YELLOW}=== COMMANDS ===${NC}\"\necho -e \"Start:   ${GREEN}cd $PROJECT_DIR && ./start.sh${NC}\"\necho -e \"Stop:    ${GREEN}./stop.sh${NC}\"\necho -e \"Status:  ${GREEN}./status.sh${NC}\"\necho\necho -e \"${YELLOW}=== ACCESS URLS ===${NC}\"\necho -e \"Dashboard: ${GREEN}http://localhost:3000${NC}\"\necho -e \"API:       ${GREEN}http://localhost:8001${NC}\"\necho -e \"API Docs:  ${GREEN}http://localhost:8001/docs${NC}\"\necho\nif groups $USER | grep -q docker; then\n    print_success \"Ready to start! Run: cd $PROJECT_DIR && ./start.sh\"\nelse\n    print_warning \"Please log out and back in for Docker permissions, then run: cd $PROJECT_DIR && ./start.sh\"\nfi\necho"
