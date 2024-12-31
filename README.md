# Instalação do Zabbix Proxy e Agent 7.2

Este repositório contém um script para configurar o **Zabbix Proxy 7.2** e o **Zabbix Agent 7.2** no seu sistema. O script realiza várias tarefas para garantir que o ambiente esteja configurado corretamente, desde a criação de usuários e permissões até a cópia de arquivos e bibliotecas necessárias.

## Aviso

Recomenda-se desinstalar qualquer outra versão do Zabbix Proxy e Agent antes de executar este script para evitar conflitos durante a instalação.

Os binários utilizados neste script foram compilados em um sistema FreeBSD 14 e copiados para serem executados no PfSense.

Este script foi desenvolvido e testado **exclusivamente para o PfSense CE 2.7**. O uso em outras versões ou sistemas pode não funcionar como esperado.

## Pré-requisitos

Antes de começar, certifique-se de ter:

- **Acesso root** ou permissões equivalentes no sistema.
- **Git instalado** para clonar este repositório.

```bash
pkg install git
```

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

O script realiza os seguintes passos para configurar o **Zabbix Proxy** e o **Zabbix Agent**:

1. **Pergunta Dados de Configuração:**
   - Solicita o modo do Proxy (ativo ou passivo).
   - Solicita o endereço do servidor Zabbix.
   - Solicita o nome do Proxy.
   - Solicita o nome do Agente.

2. **Detecta o Diretório Atual:**
   - Usa o diretório de execução como origem dos arquivos.

3. **Cria Usuário e Grupo `zabbix`:**
   - Adiciona o usuário `zabbix` e o grupo `zabbix` ao sistema, caso ainda não existam.

4. **Copia Arquivos Essenciais:**
   - Copia binários do Proxy para `/usr/local/sbin`.
   - Copia binários do Agent para `/usr/local/sbin`.
   - Copia arquivos de configuração do Proxy para `/usr/local/etc/zabbix72`.
   - Copia arquivos de configuração do Agent para `/usr/local/etc/zabbix`.
   - Copia bibliotecas adicionais para `/usr/local/lib/zabbix`.
   - Copia bibliotecas do diretório `libs` para `/usr/local/lib`.

5. **Cria Diretórios Necessários:**
   - Garante a existência dos diretórios:
     - `/var/log/zabbix` para logs.
     - `/var/run/zabbix` para arquivos de PID.
     - Outros necessários para a execução do Zabbix Proxy e Agent.

6. **Ajusta Permissões:**
   - Configura o proprietário e as permissões corretas para os arquivos e diretórios.

7. **Configura os Scripts de Inicialização:**
   - Cria um script de inicialização para o Proxy em `/usr/local/etc/rc.d/zabbix_proxy`.
   - Cria um script de inicialização para o Agent em `/usr/local/etc/rc.d/zabbix_agent`.

8. **Adiciona os Serviços ao `rc.conf`:**
   - Configura o Zabbix Proxy e Agent para iniciarem automaticamente com o sistema.

9. **Reinicia os Serviços:**
   - Inicia os serviços Zabbix Proxy e Agent e verifica seus status.

## Verificação Pós-Instalação

1. **Verificar o Status dos Serviços:**

   Após a execução do script, verifique se os serviços estão rodando corretamente:

   ```bash
   service zabbix_proxy status
   service zabbix_agent status
   ```

2. **Verificar Logs:**

   Caso encontre problemas, consulte os logs:

   ```bash
   tail -n 50 /var/log/zabbix/zabbix_proxy.log
   tail -n 50 /var/log/zabbix/zabbix_agentd.log
   ```

## Contribuições

Sinta-se à vontade para abrir issues ou pull requests para melhorias e correções no script.

## Licença

Este projeto é distribuído sob a licença [MIT](LICENSE).
