#!/bin/sh

# Caminhos dos arquivos descompactados
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Pergunta o modo do Zabbix Proxy
echo "Digite o modo do Zabbix Proxy (0 para ativo, 1 para passivo):"
read -r ZABBIX_PROXY_MODE

if [ "$ZABBIX_PROXY_MODE" != "0" ] && [ "$ZABBIX_PROXY_MODE" != "1" ]; then
    echo "Modo inválido. Escolha 0 (ativo) ou 1 (passivo)."
    exit 1
fi

# Pergunta o endereço do servidor Zabbix
echo "Digite o endereço do servidor Zabbix (exemplo: zabbix.example.com):"
read -r ZABBIX_SERVER

if [ -z "$ZABBIX_SERVER" ]; then
    echo "Endereço do servidor Zabbix não pode estar vazio."
    exit 1
fi

# Pergunta o nome do proxy
echo "Digite o nome do Proxy:"
read -r ZABBIX_PROXY_NAME

if [ -z "$ZABBIX_PROXY_NAME" ]; then
    echo "O nome do Proxy não pode estar vazio."
    exit 1
fi

# Pergunta o nome do agente
echo "Deseja instalar o agente ? (y/n) default n:"
read -r INSTALL_AGENT
INSTALL_AGENT=${INSTALL_AGENT:-n}

if [ "$INSTALL_AGENT" == "y" ]; then
    # Pergunta o nome do agente
    echo "Digite o nome do Agente:"
    read -r ZABBIX_AGENT_NAME
    if [ -z "$ZABBIX_AGENT_NAME" ]; then
        echo "O nome do Agente não pode estar vazio."
        exit 1
    fi
fi

# Caminho do arquivo de configuração
ZABBIX_PROXY_CONF="$SOURCE_DIR/zabbix72/zabbix_proxy.conf"

if [ ! -f "$ZABBIX_PROXY_CONF" ]; then
    echo "Erro: Arquivo de configuração $ZABBIX_PROXY_CONF não encontrado."
    exit 1
fi

# Substitui as configurações no arquivo de configuração
echo "Atualizando configurações no arquivo $ZABBIX_PROXY_CONF..."

sed -i.bak \
    -e "s/^Server=.*$/Server=$ZABBIX_SERVER/" \
    -e "s/^ServerActive=.*$/ServerActive=$ZABBIX_SERVER/" \
    -e "s/^Hostname=.*$/Hostname=$ZABBIX_PROXY_NAME/" \
    -e "s/^ProxyMode=.*$/ProxyMode=$ZABBIX_PROXY_MODE/" \
    "$ZABBIX_PROXY_CONF"

ZABBIX_AGENT_CONF="$SOURCE_DIR/agent/zabbix_agentd.conf"

if [ "$INSTALL_AGENT" == "y" ]; then
    # Substitui as configurações no arquivo de configuração do agente
    echo "Atualizando configurações no arquivo $ZABBIX_AGENT_CONF..."
    sed -i.bak \
        -e "s/^Hostname=.*$/Hostname=$ZABBIX_AGENT_NAME/" \
        "$ZABBIX_AGENT_CONF"
fi

# Destinos dos arquivos
BIN_DIR="/usr/local/sbin"
BIN_JS_DIR="/usr/local/bin"
CONF_DIR="/usr/local/etc/zabbix72"
LIB_DIR="/usr/local/lib/zabbix"
DB_DIR="/var/lib/zabbix"
LOG_DIR="/var/log/zabbix"
LOG_FILE="$LOG_DIR/zabbix_proxy.log"
AGENT_LOG_FILE="$LOG_DIR/zabbix_agentd.log"
RC_SCRIPT="/usr/local/etc/rc.d/zabbix_proxy"

# Verifica se o diretório de origem existe
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Erro: Diretório $SOURCE_DIR não encontrado. Certifique-se de que o pacote foi descompactado corretamente."
    exit 1
fi

# Criação do usuário e grupo zabbix
echo "Criando o usuário e grupo 'zabbix'..."
if ! pw group show zabbix >/dev/null 2>&1; then
    pw groupadd zabbix
    echo "Grupo 'zabbix' criado."
else
    echo "Grupo 'zabbix' já existe."
fi

if ! pw user show zabbix >/dev/null 2>&1; then
    pw useradd -n zabbix -g zabbix -d /nonexistent -s /usr/sbin/nologin -c "Zabbix User"
    echo "Usuário 'zabbix' criado."
else
    echo "Usuário 'zabbix' já existe."
fi

# Criação dos diretórios necessários
echo "Criando diretórios necessários..."
mkdir -p "$BIN_DIR" "$BIN_JS_DIR" "$CONF_DIR" "$LIB_DIR" "$DB_DIR" "$LOG_DIR" /usr/local/lib /usr/local/etc/zabbix/

# Criando o arquivo de log do proxy e ajustando permissões
if [ ! -f "$LOG_FILE" ]; then
    echo "Criando arquivo de log $LOG_FILE..."
    touch "$LOG_FILE"
fi

if [ "$INSTALL_AGENT" == "y" ]; then
    # Criando o arquivo de log do agente e ajustando permissões
    if [ ! -f "$AGENT_LOG_FILE" ]; then
        echo "Criando arquivo de log $AGENT_LOG_FILE..."
        touch "$AGENT_LOG_FILE"
    fi
fi

echo "Ajustando permissões para o arquivo de log..."
chown -R zabbix:zabbix "$LOG_DIR"
chmod 755 "$LOG_DIR"
chmod 644 "$LOG_FILE"

if [ "$INSTALL_AGENT" == "y" ]; then
    chown -R zabbix:zabbix "$AGENT_LOG_FILE"
    chmod 644 "$AGENT_LOG_FILE"
fi

# Criando o diretório de runtime e ajustando permissões
echo "Criando diretório /var/run/zabbix..."
mkdir -p /var/run/zabbix
chown zabbix:zabbix /var/run/zabbix
chmod 755 /var/run/zabbix

# Copiando os binários do proxy
echo "Copiando binários..."
if [ -f "$SOURCE_DIR/zabbix_proxy" ]; then
    cp "$SOURCE_DIR/zabbix_proxy" "$BIN_DIR/"
else
    echo "Aviso: Arquivo 'zabbix_proxy' não encontrado."
fi

if [ "$INSTALL_AGENT" == "y" ]; then
    # Copiando os binários do agente
    echo "Copiando binários..."
    if [ -f "$SOURCE_DIR/agent/zabbix_agentd" ]; then
        cp "$SOURCE_DIR/agent/zabbix_agentd" "$BIN_DIR/"
    else
        echo "Aviso: Arquivo agent/zabbix_agentd não encontrado."
    fi
fi

# Copiando os binários zabix_proxy_js
if [ -f "$SOURCE_DIR/zabbix_proxy_js" ]; then
    cp "$SOURCE_DIR/zabbix_proxy_js" "$BIN_JS_DIR/"
else
    echo "Aviso: Arquivo 'zabbix_proxy_js' não encontrado."
fi

# Copiando arquivos de configuração do proxy
echo "Copiando arquivos de configuração..."
if [ -d "$SOURCE_DIR/zabbix72" ]; then
    cp -r "$SOURCE_DIR/zabbix72"/* "$CONF_DIR/"
else
    echo "Aviso: Diretório de configuração 'zabbix72' não encontrado."
fi

if [ "$INSTALL_AGENT" == "y" ]; then
    # Copiando arquivos de configuração do agente
    echo "Copiando arquivos de configuração..."
    if [ -d "$SOURCE_DIR/agent" ]; then
        cp "$SOURCE_DIR/agent/zabbix_agentd.conf" /usr/local/etc/zabbix/
    else
        echo "Aviso: Arquivo de configuração 'zabbix_agentd.conf' não encontrado."
    fi
fi

# Copiando bibliotecas adicionais
if [ -d "$SOURCE_DIR/zabbix" ]; then
    echo "Copiando bibliotecas adicionais..."
    cp -r "$SOURCE_DIR/zabbix"/* "$LIB_DIR/"
else
    echo "Aviso: Diretório de bibliotecas adicionais 'zabbix' não encontrado."
fi

# Copiando bibliotecas do $SOURCE_DIR/libs para /usr/local/lib
if [ -d "$SOURCE_DIR/libs" ]; then
    echo "Copiando bibliotecas do $SOURCE_DIR/libs para /usr/local/lib..."
    cp -r "$SOURCE_DIR/libs"/* /usr/local/lib/
else
    echo "Aviso: Diretório 'libs' não encontrado em $SOURCE_DIR."
fi

# Copiando banco de dados SQLite
if [ -f "$SOURCE_DIR/zabbix/zabbix_proxy.db" ]; then
    echo "Copiando banco de dados SQLite..."
    cp "$SOURCE_DIR/zabbix/zabbix_proxy.db" "$DB_DIR/"
else
    echo "Aviso: Banco de dados SQLite 'zabbix_proxy.db' não encontrado."
fi

# Ajustando permissões
echo "Ajustando permissões..."
chmod 755 "$BIN_DIR/zabbix_proxy" "$BIN_JS_DIR/zabbix_proxy_js" 2>/dev/null || true
chown -R root:wheel "$CONF_DIR" 2>/dev/null || true
chmod -R 644 "$CONF_DIR" 2>/dev/null || true
chown -R zabbix:zabbix "$DB_DIR" 2>/dev/null || true
chmod 755 "$DB_DIR" 2>/dev/null || true
chmod 644 "$DB_DIR/zabbix_proxy.db" 2>/dev/null || true
chown -R root:wheel "$LIB_DIR" 2>/dev/null || true
chmod -R 755 "$LIB_DIR" 2>/dev/null || true

# Criando o script de inicialização
echo "Criando script de inicialização do Zabbix Proxy..."
cat <<EOF > "$RC_SCRIPT"
#!/bin/sh
#
# PROVIDE: zabbix_proxy
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
# Add the following lines to /etc/rc.conf to enable zabbix_proxy:
#
# zabbix_proxy_enable="YES"
#

. /etc/rc.subr

name="zabbix_proxy"
rcvar=zabbix_proxy_enable

command="/usr/local/sbin/zabbix_proxy"
command_args="-c /usr/local/etc/zabbix72/zabbix_proxy.conf"

load_rc_config \$name
run_rc_command "\$1"
EOF

chmod +x "$RC_SCRIPT"

# Adicionando Zabbix Proxy ao rc.conf
echo "Configurando Zabbix Proxy para iniciar automaticamente..."
if ! grep -q "zabbix_proxy_enable" /etc/rc.conf; then
    echo 'zabbix_proxy_enable="YES"' >> /etc/rc.conf
fi

# Reiniciando serviço Zabbix Proxy
echo "Reiniciando o serviço Zabbix Proxy..."
service zabbix_proxy restart || echo "Erro: Não foi possível reiniciar o serviço."

# Verificando o status do serviço
echo "Verificando o status do Zabbix Proxy..."
service zabbix_proxy status || echo "Erro: Serviço Zabbix Proxy não está ativo."

if [ "$INSTALL_AGENT" == "y" ]; then
    # Criando o script de inicialização do Zabbix Agent
    echo "Criando script de inicialização do Zabbix Agent..."
    cat <<EOF > /usr/local/etc/rc.d/zabbix_agent
#!/bin/sh
#
# PROVIDE: zabbix_agent
# REQUIRE: LOGIN
# KEYWORD: shutdown
#
# Add the following lines to /etc/rc.conf to enable zabbix_agent:
#
# zabbix_agent_enable="YES"
#

. /etc/rc.subr

name="zabbix_agent"
rcvar=zabbix_agent_enable

command="/usr/local/sbin/zabbix_agentd"
command_args="-c /usr/local/etc/zabbix/zabbix_agentd.conf"

load_rc_config \$name
run_rc_command "\$1"
EOF

chmod +x /usr/local/etc/rc.d/zabbix_agent

# Adicionando Zabbix Agent ao rc.conf
echo "Configurando Zabbix Agent para iniciar automaticamente..."
if ! grep -q "zabbix_agent_enable" /etc/rc.conf; then
    echo 'zabbix_agent_enable="YES"' >> /etc/rc.conf
fi

# Reiniciando serviço Zabbix Agent
echo "Reiniciando o serviço Zabbix Agent..."
service zabbix_agent restart || echo "Erro: Não foi possível reiniciar o serviço Zabbix Agent."

# Verificando o status do serviço Zabbix Agent
echo "Verificando o status do Zabbix Agent..."
service zabbix_agent status || echo "Erro: Serviço Zabbix Agent não está ativo."
fi

echo "Configuração concluída!"
