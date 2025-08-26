#!/bin/bash
set -e

# Abrir el puerto de WireGuard en UFW
sudo ufw allow 51820/udp

# Habilitar reenvío de IP
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Borrar interfaz wg0 si existe
sudo ip link delete wg0 || true

# Levantar Docker
docker-compose down
docker-compose up -d

# Esperar a que los contenedores estén activos
sleep 10

# Detectar interfaz de salida hacia Internet
WAN_IF=$(ip route | grep default | awk '{print $5}')
echo "Usando interfaz de salida: $WAN_IF"

# Aplicar reglas de iptables dentro del contenedor
docker exec wireguard bash -c "iptables -A FORWARD -i wg0 -j ACCEPT"
docker exec wireguard bash -c "iptables -A FORWARD -o wg0 -j ACCEPT"
docker exec wireguard bash -c "iptables -t nat -A POSTROUTING -o $WAN_IF -j MASQUERADE"