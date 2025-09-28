# AutoClick Dashboard

Sistema automatizado para abertura e fechamento de sites em intervalos configuráveis, com dashboard web para monitoramento e gerenciamento.

## 🚀 Características

- **Dashboard Web Moderno**: Interface React com componentes shadcn/ui
- **Gerenciamento de Sites**: Adicionar, remover e configurar sites para autoclick
- **Logs em Tempo Real**: Monitoramento completo de atividades e erros
- **Configuração Flexível**: Intervalos personalizáveis e configurações avançadas
- **API REST**: Backend FastAPI para todas as operações
- **Banco de Dados**: MongoDB para persistência de dados
- **Compatibilidade**: Linux (Ubuntu, Debian, Kali, CentOS, Fedora)

## 📋 Pré-requisitos

- Sistema operacional Linux (recomendado: Kali Linux)
- Conexão com internet para instalação de dependências
- Permissões sudo para instalação de pacotes do sistema

## 🔧 Instalação Automática

### Método 1: Instalação Direta

```bash
# Download e execute o instalador
curl -fsSL https://raw.githubusercontent.com/seu-usuario/autoclick-dashboard/main/install.sh | bash
```

### Método 2: Clone e Instale

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/autoclick-dashboard.git
cd autoclick-dashboard

# Execute o instalador
chmod +x install.sh
./install.sh
```

### Método 3: Download Manual

1. Baixe o arquivo `install.sh`
2. Torne-o executável: `chmod +x install.sh`
3. Execute: `./install.sh`

## 🚀 Uso

### Iniciar o Sistema

```bash
cd ~/autoclick-dashboard
./start.sh
```

### Acessar a Interface

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001
- **Documentação API**: http://localhost:8001/docs

### Parar o Sistema

```bash
./stop.sh
```

## 📱 Funcionalidades

### Dashboard Principal
- Estatísticas em tempo real
- Status do serviço (ativo/pausado)
- Métricas de sucessos e erros
- Tempo de atividade

### Gerenciamento de Sites
- Adicionar URLs para autoclick
- Ativar/desativar sites individualmente
- Remover sites da lista
- Visualizar estatísticas por site

### Sistema de Logs
- Logs em tempo real de todas as atividades
- Filtros por tipo (sucesso, erro, info)
- Busca textual nos logs
- Exportação de logs em JSON

### Configurações
- Intervalo entre acessos (mínimo 5 segundos)
- Timeout de carregamento (mínimo 10 segundos)
- Número máximo de tentativas
- User Agent personalizado

## 🔧 Configuração Manual

### Variáveis de Ambiente

**Backend (.env)**:
```bash
MONGO_URL=mongodb://localhost:27017
DB_NAME=autoclick_db
ENVIRONMENT=production
```

**Frontend (.env)**:
```bash
REACT_APP_BACKEND_URL=http://localhost:8001
```

### Estrutura de Pastas

```
autoclick-dashboard/
├── backend/
│   ├── server.py
│   ├── requirements.txt
│   └── .env
├── frontend/
│   ├── src/
│   ├── package.json
│   └── .env
├── install.sh
├── start.sh
├── stop.sh
└── README.md
```

## 🔍 Troubleshooting

### MongoDB não inicia
```bash
# Verificar se está rodando
pgrep mongod

# Iniciar manualmente
mongod --dbpath ~/mongodb-data --fork --logpath ~/mongodb-data/mongodb.log
```

### Frontend não carrega
```bash
# Verificar logs
cd ~/autoclick-dashboard/frontend
yarn start
```

### Backend não responde
```bash
# Verificar logs
cd ~/autoclick-dashboard/backend
source venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8001
```

### Problemas de dependências
```bash
# Reinstalar dependências do frontend
cd ~/autoclick-dashboard/frontend
rm -rf node_modules
yarn install

# Reinstalar dependências do backend
cd ~/autoclick-dashboard/backend
source venv/bin/activate
pip install -r requirements.txt --force-reinstall
```

## 🛡️ Segurança

- O sistema roda em localhost por padrão
- MongoDB configurado sem autenticação para uso local
- Firewall recomendado para bloquear portas externas
- User Agent configurável para evitar detecção

## 🔄 Atualizações

```bash
# Parar o sistema
./stop.sh

# Atualizar código
git pull origin main

# Reinstalar dependências se necessário
cd frontend && yarn install
cd ../backend && source venv/bin/activate && pip install -r requirements.txt

# Reiniciar
./start.sh
```

## 📝 Logs e Monitoramento

- **Logs do sistema**: `~/mongodb-data/mongodb.log`
- **Logs do backend**: Via interface ou console
- **Logs do frontend**: Via browser console
- **Dados do MongoDB**: `~/mongodb-data/`

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## ⚠️ Disclaimer

Este software é destinado apenas para fins educacionais e testes. Use responsavelmente e respeite os termos de serviço dos sites acessados.

## 📞 Suporte

Para suporte, abra uma issue no GitHub ou entre em contato através dos canais oficiais.