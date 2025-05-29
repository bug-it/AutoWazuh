#!/bin/bash

# Cores ANSI
VERDE='\033[1;32m'
AMARELO='\033[1;33m'
AZUL_CLARO="\e[96m"
ROXO_CLARO="\e[95m"
BRANCO="\e[97m"
VERMELHO="\e[91m"
NC='\033[0m'

# Função de status
status() {
  if [ $? -eq 0 ]; then
    echo -e "${VERDE}✅ Concluído${NC}\n"
  else
    echo -e "${VERMELHO}❌ Falhou${NC}\n"
  fi
}

# Verificação de Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${VERMELHO}❌ Este script precisa ser executado como root.${NC}"
  exit 1
fi

clear

# Banner ASCII
echo -e "${AZUL_CLARO}"
echo "  █████╗ ██╗   ██╗████████╗ ██████╗     ██╗    ██╗ █████╗ ███████╗██╗   ██╗██╗  ██╗"
echo " ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗    ██║    ██║██╔══██╗╚══███╔╝██║   ██║██║  ██║"
echo " ███████║██║   ██║   ██║   ██║   ██║    ██║ █╗ ██║███████║  ███╔╝ ██║   ██║███████║"
echo " ██╔══██║██║   ██║   ██║   ██║   ██║    ██║███╗██║██╔══██║ ███╔╝  ██║   ██║██╔══██║"
echo " ██║  ██║╚██████╔╝   ██║   ╚██████╔╝    ╚███╔███╔╝██║  ██║███████╗╚██████╔╝██║  ██║"
echo " ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝      ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "                                 ${ROXO_CLARO}Auto Instalação do Wazuh${NC}\n"

# Variáveis
LOGFILE="wazuh_instalacao.log"
INSTALLER_URL="https://packages.wazuh.com/4.8/wazuh-install.sh"
INSTALLER_FILE="wazuh-install.sh"
PASSWORD_URL="https://packages.wazuh.com/4.7/wazuh-passwords-tool.sh"
PASSWORD_TOOL="wazuh-passwords-tool.sh"

# Download do instalador
echo -e "${AMARELO}📥 Baixando script de instalação do Wazuh...${NC}"
curl -sO "$INSTALLER_URL"
chmod +x "$INSTALLER_FILE"
status

# Instalação do Wazuh
echo -e "${AMARELO}📦 Iniciando instalação do Wazuh (isso pode levar alguns minutos)... Aguarde...${NC}"
bash "$INSTALLER_FILE" -a > "$LOGFILE"
status

# Extração de credenciais
USER=$(grep -A2 "You can access the web interface" "$LOGFILE" | grep "User" | awk '{print $2}')
PASS=$(grep -A2 "You can access the web interface" "$LOGFILE" | grep "Password" | awk '{print $2}')
IP=$(hostname -I | awk '{print $1}')

# Exibir resultado
echo -e "${AMARELO}User: ${AZUL_CLARO}${USER}${NC}"
echo -e "${AMARELO}Password: ${AZUL_CLARO}${PASS}${NC}"

# Troca de senha do usuário admin
echo -e "\n${AMARELO}🔧 Agora vamos alterar a senha do usuário '${AZUL_CLARO}admin${AMARELO}' do Wazuh Dashboard.${NC}"

# Validação de senha
while true; do
  read -s -p "$(echo -e "${BRANCO}🔑 Digite uma nova senha para 'admin': ${NC}")" NOVA_SENHA
  echo -e "\n${AMARELO}🔑 Senha digitada: ${AZUL_CLARO}${NOVA_SENHA}"

  # Requisitos: 8-64 caracteres, 1 minúscula, 1 maiúscula, 1 número, 1 símbolo (.*+?-)
  if [[ ${#NOVA_SENHA} -ge 8 && ${#NOVA_SENHA} -le 64 &&
        "$NOVA_SENHA" =~ [a-z] &&
        "$NOVA_SENHA" =~ [A-Z] &&
        "$NOVA_SENHA" =~ [0-9] &&
        "$NOVA_SENHA" =~ [\.\*\+\?\-] ]]; then
    break
  else
    echo -e "${VERMELHO}❌ Senha inválida. ${BRANCO}Ela deve ter entre 8 e 64 caracteres e conter pelo menos uma letra maiúscula, uma minúscula, um número e um símbolo (${VERMELHO}.*+?-${BRANCO}).\n${NC}"
  fi
done

echo -e "${VERDE}✅ Senha válida.\n${NC}"

# Baixar ferramenta de alteração de senha
cd /var/ossec/bin || exit
echo -e "${AMARELO}📥 Baixando ferramenta de troca de senha...${NC}"
curl -sO "$PASSWORD_URL"
chmod +x "$PASSWORD_TOOL"
status

# Aplicar nova senha
echo -e "${AMARELO}🔐 Aplicando nova senha...${NC}"
bash "$PASSWORD_TOOL" -u admin -p "$NOVA_SENHA" &>/dev/null	
status

# Reiniciar serviço
echo -e "${AMARELO}♻️ Reiniciando o serviço wazuh-manager...${NC}"
systemctl restart wazuh-manager &>/dev/null	
status

# Salvar credenciais em arquivo
echo -e "User: $USER\nPassword: $NOVA_SENHA" > token.txt

# Caminhos finais
echo -e "\n${AMARELO}📝 Credenciais salvas em ${AZUL_CLARO}$(realpath token.txt)${NC}"
echo -e "${AMARELO}📄 Log completo disponível em ${AZUL_CLARO}$(realpath $LOGFILE)${NC}\n"

echo -e "\n${AMARELO}🔐 Acesso ao Wazuh Dashboard:${NC}"
echo -e "${AMARELO}URL: ${AZUL_CLARO}https://${IP}:443${NC}"
echo -e "${AMARELO}User: ${AZUL_CLARO}${USER}${NC}"
echo -e "${AMARELO}Password: ${AZUL_CLARO}${NOVA_SENHA}\n${NC}"
