#!/bin/sh

# Caminhos dos arquivos descompactados
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Destinos dos arquivos
BIN_DIR="/usr/local/sbin"
BIN_JS_DIR="/usr/local/bin"
CONF_DIR="/usr/local/etc/zabbix72"
LIB_DIR="/usr/local/lib/zabbix"
DB_DIR="/var/lib/zabbix"
LOG_DIR="/var/log/zabbix"
LOG_FILE="$LOG_DIR/zabbix_proxy.log"
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
mkdir -p "$BIN_DIR" "$BIN_JS_DIR" "$CONF_DIR" "$LIB_DIR" "$DB_DIR" "$LOG_DIR" /usr/local/lib

# Criando o arquivo de log e ajustando permissões
if [ ! -f "$LOG_FILE" ]; then
    echo "Criando arquivo de log $LOG_FILE..."
    touch "$LOG_FILE"
fi
echo "Ajustando permissões para o arquivo de log..."
chown -R zabbix:zabbix "$LOG_DIR"
chmod 755 "$LOG_DIR"
chmod 644 "$LOG_FILE"

# Criando o diretório de runtime e ajustando permissões
echo "Criando diretório /var/run/zabbix..."
mkdir -p /var/run/zabbix
chown zabbix:zabbix /var/run/zabbix
chmod 755 /var/run/zabbix

# Copiando os binários
echo "Copiando binários..."
if [ -f "$SOURCE_DIR/zabbix_proxy" ]; then
    cp "$SOURCE_DIR/zabbix_proxy" "$BIN_DIR/"
else
    echo "Aviso: Arquivo 'zabbix_proxy' não encontrado."
fi

if [ -f "$SOURCE_DIR/zabbix_proxy_js" ]; then
    cp "$SOURCE_DIR/zabbix_proxy_js" "$BIN_JS_DIR/"
else
    echo "Aviso: Arquivo 'zabbix_proxy_js' não encontrado."
fi

# Copiando arquivos de configuração
echo "Copiando arquivos de configuração..."
if [ -d "$SOURCE_DIR/zabbix72" ]; then
    cp -r "$SOURCE_DIR/zabbix72"/* "$CONF_DIR/"
else
    echo "Aviso: Diretório de configuração 'zabbix72' não encontrado."
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

echo "Configuração concluída!"

