# Docker Compose para Serviços de Rede e Diretórios

Este repositório contém uma configuração do Docker Compose para implementar diversos serviços de rede e diretórios, como DNS, OpenLDAP, Nginx, FTP, e Samba. Cada serviço está configurado para rodar em containers Docker interconectados por redes virtuais.

## Serviços

### 1. **DNS (BIND9)**
- **Imagem**: `ubuntu/bind9`
- **Portas**: Não expostas diretamente
- **Volumes**:
  - `./DNS/named.conf.local:/etc/bind/named.conf.local`
  - `./DNS/named.conf.options:/etc/bind/named.conf.options`
- **Rede**: `server_network`
- **Função**: Servidor DNS utilizando BIND9, com arquivos de configuração locais.

### 2. **Nginx**
- **Imagem**: `nginx:alpine`
- **Portas**: `8080:80`
- **Volumes**:
  - `./nginx/nginx.conf:/etc/nginx/conf.d/default.conf`
  - `./nginx/html/:/usr/share/nginx/html/`
- **Redes**: `server_network`, `client_network`
- **Função**: Servidor web Nginx, configurado para servir arquivos estáticos e redirecionar tráfego HTTP.

### 3. **OpenLDAP**
- **Imagem**: `bitnami/openldap:latest`
- **Container Name**: `openldap`
- **Portas**: 
  - `389:389` (LDAP)
  - `636:636` (LDAPS)
- **Volumes**:
  - `./data/certificates:/container/service/slapd/assets/certs`
  - `./data/slapd/database:/var/lib/ldap`
  - `./data/slapd/config:/etc/ldap/slapd.d`
- **Ambiente**:
  - `LDAP_ORGANISATION=ramhlocal`
  - `LDAP_DOMAIN=ramhlocal.com`
  - `LDAP_ADMIN_USERNAME=admin`
  - `LDAP_ADMIN_PASSWORD=admin_pass`
  - `LDAP_BASE_DN=dc=ramhlocal,dc=com`
  - `LDAP_TLS_CRT_FILENAME=server.crt`
  - `LDAP_TLS_KEY_FILENAME=server.key`
  - `LDAP_READONLY_USER=true`
- **Rede**: `server_network`
- **Função**: Servidor LDAP para autenticação e gerenciamento de diretórios, com suporte a TLS.

### 4. **ProFTPD**
- **Imagem**: `stilliard/pure-ftpd:hardened`
- **Container Name**: `proftpd_test`
- **Portas**: 
  - `21:21` (FTP)
  - `30000-30009:30000-30009` (FTP Passive Mode)
- **Ambiente**:
  - `PUBLICHOST=localhost`
  - `FTP_USER_NAME=anonymous`
  - `FTP_USER_PASS=anonymous`
  - `FTP_USER_HOME=/home/ftpusers/ftpuser`
- **Volumes**:
  - `./ftp_data:/home/ftpusers/ftpuser`
- **Rede**: `server_network`
- **Função**: Servidor FTP com acesso anônimo e diretório compartilhado para arquivos.

### 5. **Samba**
- **Imagem**: `dperson/samba`
- **Container Name**: `samba_server`
- **Portas**:
  - `139:139`
  - `445:445`
- **Ambiente**:
  - `USERID=1000`
  - `GROUPID=1000`
- **Volumes**:
  - `./samba_data:/mount`
  - `./publico:/samba/publico`
  - `./privaddo:/samba/privado`
- **Comando**:
  - `-u "admin;admin"`
  - `-s "public;/mount;yes;no;no;all"`
- **Rede**: `server_network`
- **Função**: Compartilhamento de arquivos SMB/CIFS com diretórios públicos e privados.

## Redes

- **server_network**: Rede interna para comunicação entre servidores.
- **client_network**: Rede para comunicação com clientes externos.

## Volumes

- **openldap_data**: Volume persistente para dados do OpenLDAP.

## Topologia de Rede

A topologia de rede configurada neste ambiente Docker é composta por diferentes serviços interconectados através de redes virtuais isoladas, com a adição de um firewall como gateway para a comunicação externa.

### Visão Geral

- **Firewall**: O firewall serve como gateway para a rede, controlando o tráfego de entrada e saída, além de fornecer uma camada de segurança para os serviços internos.
- **Serviços de Rede**: Incluem DNS (BIND9), Nginx, OpenLDAP, FTP e Samba. Esses serviços estão conectados a redes internas e se comunicam entre si.
- **Redes Internas**: Dois tipos de redes virtuais são utilizados:
  - **server_network**: Rede interna para comunicação entre os servidores (DNS, Nginx, OpenLDAP, FTP, Samba).
  - **client_network**: Rede para comunicação com os clientes externos (navegação através do Nginx, FTP, etc).

### Diagrama da Topologia

````bash
                    +-----------------+
                    |     CLIENTES    |
                    +--------+--------+
                             |
                             |
                      +------v-------+
                      |  FIREWALL    |
                      |  (Gateway)   |
                      +------^-------+
                             |
           +-----------------+-----------------+
           |                 |                 |
  +--------v--------+ +------v-------+ +-------v-------+
  |     NGINX       | |     OPENLDAP  | |     SAMBA     |
  +-----------------+ +--------------+ +---------------+
           |                      |
  +--------v--------+         +------v-------+
  |      DNS        |         |     FTP      |
  +-----------------+         +--------------+

````


### Descrição da Topologia

1. **Clientes**: Clientes externos que acessam os serviços (por exemplo, o servidor Nginx) através do firewall. Eles podem interagir com o Nginx para acessar páginas web, o FTP para transferências de arquivos ou o Samba para compartilhamentos de arquivos.

2. **Firewall (Gateway)**: O firewall atua como a camada de segurança entre os clientes externos e os serviços internos. Ele pode ser configurado para permitir ou bloquear tráfego específico, dependendo da política de segurança definida. Ele gerencia a comunicação entre o cliente e os serviços internos, como o Nginx, OpenLDAP, FTP, e Samba.

3. **Serviços Internos**:
   - **Nginx**: Responsável por servir conteúdo web e redirecionar o tráfego de entrada para os serviços apropriados.
   - **DNS (BIND9)**: Responsável pela resolução de nomes de domínio dentro da rede.
   - **OpenLDAP**: Servidor de diretórios LDAP usado para autenticação e gerenciamento de usuários.
   - **FTP (ProFTPD)**: Servidor FTP para transferência de arquivos, com um usuário anônimo configurado.
   - **Samba**: Servidor de compartilhamento de arquivos SMB/CIFS, permitindo o acesso a arquivos entre máquinas na rede.

### Fluxo de Dados

1. **Clientes** acessam o serviço Nginx via IP público, com o tráfego passando pelo **Firewall**.
2. O **Firewall** direciona o tráfego para o **Nginx** ou outros serviços, conforme a configuração da rede.
3. Os serviços internos como **DNS**, **OpenLDAP**, **FTP**, e **Samba** se comunicam através das redes internas (`server_network` e `client_network`), mas o tráfego externo é filtrado pelo **Firewall**.

### Configuração do Firewall

O firewall pode ser configurado como uma máquina virtual ou container Docker atuando como um gateway, com regras de filtragem de tráfego baseadas nas necessidades de segurança da rede.

### Considerações Finais

- O uso de um **firewall** como gateway garante maior controle sobre o tráfego que entra e sai da rede, aumentando a segurança.
- Os serviços internos estão isolados nas redes virtuais, o que impede o acesso direto não autorizado aos containers.
- Esta topologia é útil para testes, ambientes de desenvolvimento e para redes que exigem comunicação controlada com o mundo externo.


## Como Usar

1. **Requisitos**: Certifique-se de ter o [Docker](https://www.docker.com/get-started) e o [Docker Compose](https://docs.docker.com/compose/install/) instalados.

2. **Iniciar os serviços**:
   ```bash
   docker-compose up -d
