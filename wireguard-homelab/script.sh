#!/bin/bash

set -e

# Detectar interfaz WAN automáticamente (excluye loopback y wg)
WAN_IF=$(ip route | grep '^default' | awk '{print $5}')
WG_IF="wg0"

echo "[INFO] WAN Interface detected: $WAN_IF"
echo "[INFO] WireGuard Interface: $WG_IF"

# Habilitar reenvío de IP
sudo sysctl -w net.ipv4.ip_forward=1
grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Reiniciar contenedores
docker-compose down
docker-compose up -d

# Darle un tiempo a WireGuard para que levante
sleep 10

# Limpiar reglas previas de iptables para evitar duplicados
sudo iptables -D FORWARD -i $WG_IF -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -o $WG_IF -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -i $WAN_IF -o $WG_IF -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -i $WG_IF -o $WAN_IF -j ACCEPT 2>/dev/null || true
sudo iptables -t nat -D POSTROUTING -o $WAN_IF -j MASQUERADE 2>/dev/null || true

# Agregar reglas de iptables
sudo iptables -A FORWARD -i $WG_IF -j ACCEPT
sudo iptables -A FORWARD -o $WG_IF -j ACCEPT
sudo iptables -A FORWARD -i $WAN_IF -o $WG_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $WG_IF -o $WAN_IF -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o $WAN_IF -j MASQUERADE

echo "[INFO] VPN homelab server is configured and running."
