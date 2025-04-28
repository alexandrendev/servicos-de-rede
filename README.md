# Docker Compose para Serviços de Rede e Diretórios

Este repositório contém uma configuração do Docker Compose para implementar diversos serviços de rede e diretórios, como DNS, OpenLDAP, Nginx, FTP, e Samba. Cada serviço está configurado para rodar em containers Docker interconectados por redes virtuais.

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




# Serviços

# 1. **DNS (BIND9)**
- **Imagem**: `ubuntu/bind9`
- **Portas**: Não expostas diretamente
- **Volumes**:
  - `./DNS/named.conf.local:/etc/bind/named.conf.local`
  - `./DNS/named.conf.options:/etc/bind/named.conf.options`
- **Rede**: `server_network`
- **Função**: Servidor DNS utilizando BIND9, com arquivos de configuração locais.

##### O arquivo named.conf.local

O arquivo `named.conf.local` é utilizado para definir as zonas do servidor DNS. Cada zona representa um domínio e deve apontar para um arquivo de configuração específico. 

Exemplo de configuração:

```bash
zone "exemplo.com" {
    type master;
    file "/etc/bind/db.exemplo.com";
};

zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.1";
};
```

### O arquivo db.exemplo.com

Este é o arquivo que define o mapeamento de nomes para IPs. Ele contém informações como o servidor autoritativo (SOA), os registros de nomes (A) e os servidores de nomes (NS).

Exemplo:

```bash
$TTL    604800
@       IN      SOA     ns.exemplo.com. root.exemplo.com. (
                        2         ; Serial
                        604800    ; Refresh
                        86400     ; Retry
                        2419200   ; Expire
                        604800 )  ; Negative Cache TTL
;
@       IN      NS      ns.exemplo.com.
@       IN      A       192.168.1.100
ns      IN      A       192.168.1.100
www     IN      A       192.168.1.101
ftp     IN      A       192.168.1.102
```

### O arquivo db.192.168.1

Este é o arquivo que define o mapeamento de IPs para nomes (resolução reversa). 

Exemplo:

```bash
$TTL    604800
@       IN      SOA     ns.exemplo.com. root.exemplo.com. (
                        1         ; Serial
                        604800    ; Refresh
                        86400     ; Retry
                        2419200   ; Expire
                        604800 )  ; Negative Cache TTL
;
@       IN      NS      ns.exemplo.com.
100     IN      PTR     ns.exemplo.com.
101     IN      PTR     www.exemplo.com.
102     IN      PTR     ftp.exemplo.com.
```

---------------------------------

# 2. **Nginx**
- **Imagem**: `nginx:alpine`
- **Portas**: `8080:80`
- **Volumes**:
  - `./nginx/nginx.conf:/etc/nginx/conf.d/default.conf`
  - `./nginx/html/:/usr/share/nginx/html/`
- **Redes**: `server_network`, `client_network`
- **Função**: Servidor web Nginx, configurado para servir arquivos estáticos e redirecionar tráfego HTTP.

### O arquivo `nginx.conf`

```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
}

http {

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	gzip on;


	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;

	server {
    	listen       80 default_server;
    	listen       [::]:80 default_server;
    	server_name  _;
    	root         /usr/share/nginx/html;
	}
	
	server {
		server_name  example.com;
		root         /var/www/example.com/;
		access_log   /var/log/nginx/access.log;
		error_log    /var/log/nginx/error.log;
	}

}

```

### Explicando algumas diretivas

Aqui o bloco onde realizamos as configurações é o bloco `http`, onde colocamos os blocos `server` com as configurações do servidor.

- `listen       80 default_server;`: Define o servidor para escutar na porta 80 (ipv4)
- `listen       [::]:80 default_server;`: Define o servidor para escutar na porta 80 (ipv6)
- `root         /var/www/example.com/;`: Define o diretório raiz onde o servidor irá buscar os arquivos .html
- `access_log && error_log`: Definem os diretórios onde o servidor registrará arquivos de log.
------------------------

## 3. **OpenLDAP**

- **Imagem**: `bitnami/openldap:latest`
- **Container Name**: `openldap`
- **Portas Expostas**:
  - `389:389` → Conexões LDAP sem TLS
  - `636:636` → Conexões LDAP com TLS (LDAPS)

- **Volumes Montados**:
  | Volume Local                           | Volume no Container                           | Descrição                                   |
  |----------------------------------------|----------------------------------------------|---------------------------------------------|
  | `./data/certificates`                  | `/container/service/slapd/assets/certs`      | Certificados TLS (server.crt, server.key, etc.) |
  | `./data/slapd/database`                | `/var/lib/ldap`                              | Banco de dados LDAP persistente             |
  | `./data/slapd/config`                  | `/etc/ldap/slapd.d`                          | Configuração dinâmica do OpenLDAP          |

- **Variáveis de Ambiente**:
  | Variável de Ambiente                 | Descrição                                                                       |
  |--------------------------------------|---------------------------------------------------------------------------------|
  | `LDAP_ORGANISATION`                  | Nome da organização no LDAP (ex: `ramhlocal`)                                  |
  | `LDAP_DOMAIN`                        | Domínio LDAP (ex: `ramhlocal.com` → `dc=ramhlocal,dc=com`)                      |
  | `LDAP_ADMIN_USERNAME`                | Nome de usuário do administrador LDAP (ex: `admin`)                            |
  | `LDAP_ADMIN_PASSWORD`                | Senha do administrador LDAP (ex: `admin_pass`)                                 |
  | `LDAP_BASE_DN`                       | Base DN para busca no LDAP (ex: `dc=ramhlocal,dc=com`)                         |
  | `LDAP_TLS_CRT_FILENAME`              | Nome do arquivo de certificado TLS (ex: `server.crt`)                          |
  | `LDAP_TLS_KEY_FILENAME`              | Nome do arquivo de chave privada TLS (ex: `server.key`)                        |
  | `LDAP_READONLY_USER`                 | Se `true`, cria um usuário com permissão somente leitura (default: `false`)     |
  | `LDAP_READONLY_USER_USERNAME`        | Nome do usuário somente leitura (default: `user-ro`)                           |
  | `LDAP_READONLY_USER_PASSWORD`        | Senha do usuário somente leitura (default: `ro_pass`)                          |

- **Rede**: `server_network` (Rede interna para isolamento)

- **Função**: Servidor LDAP utilizado para autenticação centralizada, controle de acesso e gerenciamento de diretórios. Suporta conexões seguras através de TLS (LDAPS).


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

### O arquivo `nginx.conf`

```xml
Include /etc/proftpd/modules.conf


UseIPv6 off

<IfModule mod_ident.c>
  IdentLookups off
</IfModule>

ServerName "FTP Server"
ServerType standalone
DeferWelcome off

DefaultServer on
ShowSymlinks on

TimeoutNoTransfer 600
TimeoutStalled 600
TimeoutIdle 1200

DisplayLogin welcome.msg
DisplayChdir .message true
ListOptions "-l"

DenyFilter \*.*/

DefaultRoot ~


RequireValidShell off

Port 21


<IfModule mod_dynmasq.c>
</IfModule>

MaxInstances 30

User proftpd
Group nogroup

Umask 022 022

AllowOverwrite on

TransferLog /var/log/proftpd/xferlog
SystemLog /var/log/proftpd/proftpd.log

<IfModule mod_quotatab.c>
QuotaEngine off
</IfModule>

<IfModule mod_ratio.c>
Ratios off
</IfModule>

<IfModule mod_delay.c>
DelayEngine on
</IfModule>

<IfModule mod_ctrls.c>
ControlsEngine off
ControlsMaxClients 2
ControlsLog /var/log/proftpd/controls.log
ControlsInterval 5
ControlsSocket /var/run/proftpd/proftpd.sock
</IfModule>

<IfModule mod_ctrls_admin.c>
AdminControlsEngine off
</IfModule>

 <Anonymous ~ftp>
   User ftp
   Group nogroup

   UserAlias anonymous ftp

   RequireValidShell off

   MaxClients 10

   DisplayLogin welcome.msg
   DisplayChdir .message
   <Directory ~/share>
     <Limit READ WRITE>
       AllowAll
     </Limit>
   </Directory>
 </Anonymous>

Include /etc/proftpd/conf.d/
```

---------------------------------------

# 5. **Samba**
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

## O arquivo `smb.conf`

```shell
[global]
workgroup = WORKGROUP
server string = Samba Server %v
netbios name = debian
security = user
map to guest = bad user
dns proxy = no

[allusers]
comment = All Users
path = /home/shares/allusers
valid users = @users
force group = users
create mask = 0660
directory mask = 0771
writable = yes

[homes]
comment = Home Directories
browseable = no
valid users = %S
writable = yes
create mask = 0700
directory mask = 0700

[anonymous]
path = /home/shares/anonymous
force group = users
create mask = 0660
directory mask = 0771
browsable = yes
writable = yes
guest ok = yes
```

# Explicando algumas diretivas

## [global]
- **`workgroup`**: Define o nome do grupo de trabalho. Exemplo: `WORKGROUP`.
- **`server string`**: Descrição do servidor Samba. Exemplo: `Samba Server %v`.
- **`netbios name`**: Nome do servidor na rede. Exemplo: `debian`.
- **`security`**: Método de autenticação. `user` exige autenticação por nome de usuário e senha.
- **`map to guest`**: Mapeia usuários falhos para "guest" (usuário anônimo). Exemplo: `bad user`.
- **`dns proxy`**: Define se o Samba deve usar o proxy DNS. Exemplo: `no`.

## [allusers]
- **`path`**: Caminho do diretório compartilhado. Exemplo: `/home/shares/allusers`.
- **`valid users`**: Usuários ou grupos que têm permissão para acessar o compartilhamento. Exemplo: `@users`.
- **`create mask`**: Permissões para arquivos criados. Exemplo: `0660`.
- **`directory mask`**: Permissões para diretórios criados. Exemplo: `0771`.
- **`writable`**: Permite a gravação. Exemplo: `yes`.

## [homes]
- **`valid users`**: Usuários que podem acessar seus próprios diretórios. Exemplo: `%S` (usuário que está autenticado).
- **`browseable`**: Define se o compartilhamento é visível. Exemplo: `no`.
- **`writable`**: Permite a gravação. Exemplo: `yes`.

## [anonymous]
- **`path`**: Caminho do diretório público. Exemplo: `/home/shares/anonymous`.
- **`guest ok`**: Permite acesso sem autenticação. Exemplo: `yes`.
- **`browseable`**: Define se o compartilhamento é visível. Exemplo: `yes`.
- **`writable`**: Permite a gravação. Exemplo: `yes`.
- **`force group`**: Define o grupo para arquivos criados. Exemplo: `users`.

--------------------------------

## Redes

- **server_network**: Rede interna para comunicação entre servidores.
- **client_network**: Rede para comunicação com clientes externos.

## Volumes

- **openldap_data**: Volume persistente para dados do OpenLDAP.
