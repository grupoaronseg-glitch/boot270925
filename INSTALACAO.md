# 🚀 Guia de Instalação - AutoClick Dashboard

## Métodos de Instalação Disponíveis

### 1. 🔥 **Instalação Automática Completa (Recomendado)**
```bash
curl -fsSL https://raw.githubusercontent.com/seu-usuario/autoclick-dashboard/main/install.sh | bash
```
**ou baixe e execute:**
```bash
wget https://raw.githubusercontent.com/seu-usuario/autoclick-dashboard/main/install.sh
chmod +x install.sh
./install.sh
```

### 2. 🐳 **Instalação com Docker**
```bash
curl -fsSL https://raw.githubusercontent.com/seu-usuario/autoclick-dashboard/main/install-docker.sh | bash
```

### 3. ⚡ **Setup Rápido para Teste**
```bash
curl -fsSL https://raw.githubusercontent.com/seu-usuario/autoclick-dashboard/main/quick-setup.sh | bash
```

### 4. 📁 **Instalação Manual**
```bash
git clone https://github.com/seu-usuario/autoclick-dashboard.git
cd autoclick-dashboard
./install.sh
```

## 🖥️ Sistemas Operacionais Suportados

- ✅ **Kali Linux** (totalmente testado)
- ✅ **Ubuntu/Debian** (16.04+)
- ✅ **CentOS/RHEL** (7+)
- ✅ **Fedora** (30+)
- ✅ **Arch Linux**
- ✅ **macOS** (com Homebrew)

## 📋 Pré-requisitos

### Automático (o instalador faz tudo)
- Conexão com internet
- Permissões sudo
- Mínimo 2GB RAM
- 1GB espaço em disco

### Manual (se instalar dependências separadamente)
- Node.js 16+ e Yarn
- Python 3.8+ e pip
- MongoDB 4.4+
- Git

## 🚀 Início Rápido (3 comandos)

```bash
# 1. Download e instale
curl -fsSL https://raw.githubusercontent.com/seu-usuario/autoclick-dashboard/main/install.sh | bash

# 2. Vá para o diretório
cd ~/autoclick-dashboard

# 3. Inicie o sistema
./start.sh
```

**Pronto! Acesse:** http://localhost:3000

## 🛠️ Opções de Instalação Detalhadas

### Instalação Padrão
```bash
./install.sh
```
- Instala todas as dependências
- Configura MongoDB local
- Cria scripts de controle
- Setup completo de produção

### Instalação Docker
```bash
./install-docker.sh
```
- Usa containers Docker
- Isolamento completo
- Fácil deploy em qualquer servidor
- Inclui nginx reverse proxy

### Setup Rápido
```bash
./quick-setup.sh
```
- Instalação mínima para testes
- Menos verificações de segurança
- Ideal para desenvolvimento

## 📁 Estrutura Após Instalação

```
~/autoclick-dashboard/
├── frontend/          # Interface React
├── backend/           # API FastAPI
├── start.sh          # ▶️ Iniciar sistema
├── stop.sh           # ⏹️ Parar sistema
├── install.sh        # 🔧 Reinstalar
└── logs/             # 📋 Arquivos de log
```

## ⚙️ Comandos Principais

```bash
# Iniciar sistema
./start.sh

# Parar sistema
./stop.sh

# Ver logs em tempo real
tail -f logs/autoclick.log

# Reiniciar apenas backend
sudo supervisorctl restart backend

# Reiniciar apenas frontend
sudo supervisorctl restart frontend
```

## 🌐 URLs de Acesso

- **Dashboard:** http://localhost:3000
- **API Backend:** http://localhost:8001
- **Documentação API:** http://localhost:8001/docs
- **MongoDB:** localhost:27017

## 🔧 Configuração Personalizada

### Alterar Portas
Edite os arquivos `.env`:
```bash
# Frontend
nano frontend/.env
REACT_APP_BACKEND_URL=http://localhost:8002

# Backend
nano backend/.env
PORT=8002
```

### Configurar MongoDB Remoto
```bash
nano backend/.env
MONGO_URL=mongodb://usuario:senha@servidor:27017/autoclick_db
```

## 🔍 Solução de Problemas

### MongoDB não inicia
```bash
# Verificar status
pgrep mongod

# Iniciar manualmente
mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log
```

### Frontend não carrega
```bash
# Verificar dependências
cd ~/autoclick-dashboard/frontend
yarn install

# Verificar porta
netstat -tlnp | grep :3000
```

### Backend com erro
```bash
# Verificar logs
tail -f ~/autoclick-dashboard/logs/backend.log

# Reinstalar dependências
cd ~/autoclick-dashboard/backend
source venv/bin/activate
pip install -r requirements.txt --force-reinstall
```

### Porta ocupada
```bash
# Ver processos na porta 3000
sudo lsof -i :3000

# Matar processo
sudo kill -9 [PID]
```

## 🔄 Atualização

```bash
cd ~/autoclick-dashboard
git pull origin main
./install.sh  # Reinstala dependências se necessário
./start.sh
```

## 🗑️ Desinstalação

```bash
# Parar serviços
./stop.sh

# Remover arquivos
rm -rf ~/autoclick-dashboard

# Remover MongoDB (opcional)
rm -rf ~/mongodb-data

# Remover dependências (opcional)
sudo apt remove nodejs python3-pip mongodb-org
```

## ⚡ Instalação em Kali Linux (Especial)

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências base
sudo apt install -y curl wget git

# Executar instalador
curl -fsSL https://raw.githubusercontent.com/seu-usuario/autoclick-dashboard/main/install.sh | bash

# Iniciar
cd ~/autoclick-dashboard && ./start.sh
```

## 🎯 Testando a Instalação

Após instalar, teste as funcionalidades:

1. **Dashboard carrega:** http://localhost:3000
2. **API responde:** http://localhost:8001/api/
3. **Adicionar site:** Teste com https://example.com
4. **Ver logs:** Verifique se aparecem atividades
5. **Configurações:** Altere intervalo e salve

## 📞 Suporte

Se encontrar problemas:

1. **Logs detalhados:** `./start.sh --verbose`
2. **Verificar sistema:** `./install.sh --check`
3. **Reinstalação limpa:** `./install.sh --clean`
4. **Reportar bug:** Abra issue no GitHub

## 🔐 Segurança

- Sistema roda em localhost por padrão
- MongoDB sem autenticação (uso local)
- Configure firewall para portas externas
- Use HTTPS em produção

---

**💡 Dica:** Para uso em produção, configure domínio próprio, SSL/HTTPS e autenticação MongoDB.