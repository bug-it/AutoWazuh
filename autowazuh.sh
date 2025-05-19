#!/bin/bash

# Cores ANSI
VERDE='\033[1;32m'
AMARELO='\033[1;33m'
AZUL='\033[1;34m'
NEUTRO='\033[0m'
NEGRITO='\033[1m'

clear
# Banner estilo BIG
echo -e "${VERDE}"
echo "             _    _   _______    ____   __          __             ______  _    _   _    _ "
echo "     /\     | |  | | |__   __|  / __ \  \ \        / /     /\     |___  / | |  | | | |  | |"
echo "    /  \    | |  | |    | |    | |  | |  \ \  /\  / /     /  \       / /  | |  | | | |__| |"
echo "   / /\ \   | |  | |    | |    | |  | |   \ \/  \/ /     / /\ \     / /   | |  | | |  __  |"
echo "  / ____ \  | |__| |    | |    | |__| |    \  /\  /     / ____ \   / /__  | |__| | | |  | |"
echo " /_/    \_\  \____/     |_|     \____/      \/  \/     /_/    \_\ /_____|  \____/  |_|  |_|"
echo -e "${NEUTRO}"
echo -e "                                 ${AMARELO}Auto Instalação do Wazuh${NEUTRO}\n"

# Variáveis
LOGFILE="wazuh_instalacao.log"
INSTALLER_URL="https://packages.wazuh.com/4.8/wazuh-install.sh"
INSTALLER_FILE="wazuh-install.sh"

# Download
echo -ne "${AMARELO}📥 Baixando script de instalação do Wazuh...${NEUTRO}"
curl -sO "$INSTALLER_URL"
chmod +x "$INSTALLER_FILE"
echo -e "${VERDE}\n✅ Concluído!${NEUTRO}"

# Instalação
echo -e "\n${AMARELO}⚙️ Iniciando instalação do Wazuh (isso pode levar alguns minutos)... Aguarde...${NEUTRO}"
bash "$INSTALLER_FILE" -a > "$LOGFILE" 2>&1
echo -e "${VERDE}✅ Concluído!${NEUTRO}"

# Extração de credenciais
USER=$(grep -A2 "You can access the web interface" "$LOGFILE" | grep "User" | awk '{print $2}')
PASS=$(grep -A2 "You can access the web interface" "$LOGFILE" | grep "Password" | awk '{print $2}')
IP=$(hostname -I | awk '{print $1}')

# Salvar credenciais
echo -e "User: $USER\nPassword: $PASS" > token.txt

# Exibir resultado
echo -e "\n${AMARELO}🔐 Acesso ao Wazuh Dashboard:${NEUTRO}"
echo -e "${AMARELO}URL: ${AZUL}https://${IP}:443${NEUTRO}"
echo -e "${AMARELO}User: ${AZUL}${USER}${NEUTRO}"
echo -e "${AMARELO}Password: ${AZUL}${PASS}${NEUTRO}"

echo -e "\n${AMARELO}📝 Credenciais salvas em ${AZUL}$(realpath token.txt)${NEUTRO}"
echo -e "${AMARELO}📄 Log completo disponível em ${AZUL}$(realpath $LOGFILE)${NEUTRO}\n"
