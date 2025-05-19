#!/bin/bash

echo "=== TESTES DE SERVIÇOS DO DOCKER-COMPOSE ==="

# LDAP
echo -n "Testando LDAP... "
ldapsearch -x -H ldap://localhost:389 -D "cn=admin,dc=empresa,dc=local" -w admin -b "dc=empresa,dc=local" > /dev/null 2>&1 \
  && echo "OK" || echo "FALHOU"

# DNS
echo -n "Testando DNS (consulta via dig)... "
dig @127.0.0.1 google.com +short > /dev/null 2>&1 \
  && echo "OK" || echo "FALHOU"

# FTP
echo -n "Testando FTP... "
ftp -inv 127.0.0.1 21 <<EOF > /dev/null 2>&1
user anonymous anonymous
quit
EOF
[ $? -eq 0 ] && echo "OK" || echo "FALHOU"

# HTTP (nginx)
echo -n "Testando HTTP (nginx)... "
curl -s http://localhost:8081 > /dev/null && echo "OK" || echo "FALHOU"

# Samba
echo -n "Testando SAMBA... "
smbclient -L localhost -U admin%admin > /dev/null 2>&1 && echo "OK" || echo "FALHOU"
