# Instalação do Zabbix Proxy 7.2

Este repositório contém um script para configurar o **Zabbix Proxy 7.2** no seu sistema. O script realiza várias tarefas para garantir que o ambiente esteja configurado corretamente, desde a criação de usuários e permissões até a cópia de arquivos e bibliotecas necessárias.

## Aviso

Recomenda-se desinstalar qualquer outra versão do Zabbix Proxy antes de executar este script para evitar conflitos durante a instalação.

Os binários utilizados neste script foram compilados em um sistema FreeBSD 14 e copiados para serem executados no PfSense.

Este script foi desenvolvido e testado **exclusivamente para o PfSense CE 2.7**. O uso em outras versões ou sistemas pode não funcionar como esperado.

## Pré-requisitos

Antes de começar, certifique-se de ter:

- **Acesso root** ou permissões equivalentes no sistema.
- **Git instalado** para clonar este repositório.
- Um sistema operacional compatível com o script.

## Passos de Instalação

1. **Clone o Repositório**

   Clone este repositório no seu sistema:

   ```bash
   git clone <URL_DO_REPOSITORIO>
   ```

2. **Navegue para o Diretório do Script**

   Entre no diretório clonado:

   ```bash
   cd <DIRETORIO_DO_REPOSITORIO>
   ```

3. **Execute o Script de Instalação**

   Torne o script executável e execute-o:

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

## O Que o Script Faz?

O script realiza os seguintes passos para configurar o **Zabbix Proxy**:

1. **Detecta o Diretório Atual:**
   - Usa o diretório de execução como origem dos arquivos.

2. **Cria Usuário e Grupo `zabbix`:**
   - Adiciona o usuário `zabbix` e o grupo `zabbix` ao sistema, caso ainda não existam.

3. **Copia Arquivos Essenciais:**
   - Copia binários para `/usr/local/sbin` e `/usr/local/bin`.
   - Copia arquivos de configuração para `/usr/local/etc/zabbix72`.
   - Copia bibliotecas adicionais para `/usr/local/lib/zabbix`.
   - Copia bibliotecas do diretório `libs` para `/usr/local/lib`.

4. **Cria Diretórios Necessários:**
   - Garante a existência dos diretórios:
     - `/var/log/zabbix` para logs.
     - `/var/run/zabbix` para arquivos de PID.
     - Outros necessários para a execução do Zabbix Proxy.

5. **Ajusta Permissões:**
   - Configura o proprietário e as permissões corretas para os arquivos e diretórios.

6. **Configura o Script de Inicialização:**
   - Cria um script de inicialização em `/usr/local/etc/rc.d/zabbix_proxy`.

7. **Adiciona o Serviço ao `rc.conf`:**
   - Configura o Zabbix Proxy para iniciar automaticamente com o sistema.

8. **Reinicia o Serviço:**
   - Inicia o serviço Zabbix Proxy e verifica seu status.

## Verificação Pós-Instalação

1. **Verificar o Status do Serviço:**

   Após a execução do script, verifique se o Zabbix Proxy está rodando corretamente:

   ```bash
   service zabbix_proxy status
   ```

2. **Verificar Logs:**

   Caso encontre problemas, consulte os logs:

   ```bash
   tail -n 50 /var/log/zabbix/zabbix_proxy.log
   ```

## Contribuições

Sinta-se à vontade para abrir issues ou pull requests para melhorias e correções no script.

## Licença

Este projeto é distribuído sob a licença [MIT](LICENSE).
