# 🌐 Proyecto VPN con WireGuard y Docker

[![WireGuard](https://img.shields.io/badge/WireGuard-v1.0-red?logo=wireguard&logoColor=white)](https://www.wireguard.com/)  
[![Docker](https://img.shields.io/badge/Docker-20.10-blue?logo=docker&logoColor=white)](https://www.docker.com/)  
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-orange?logo=ubuntu&logoColor=white)](https://ubuntu.com/)  
[![Made with Bash](https://img.shields.io/badge/Shell-Bash-green?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)  

Este proyecto implementa una **VPN con WireGuard** en un **VPS** y un **HomeLab**, permitiendo conexiones seguras desde servidores locales, Windows y dispositivos móviles.  
Incluye instalación, generación de claves, configuración de peers y pasos para verificación y resolución de problemas.

---

## 📑 Índice
1. [Desarrollo de la VPN](#desarrollo-de-la-vpn)  
   - [Configuración de VPS](#configuracion-de-vps)  
   - [Configuración de Servidor local (HomeLab)](#configuración-de-servidor-local-homelab)  
   - [Cliente Windows](#configurar-un-cliente-windows)  
   - [Cliente móvil](#configurar-en-un-dispositivo-movil)  
2. [Comprobación de estado](#comprobación-de-estado)  
3. [Resolución de problemas](#resolución-de-problemas)  

---

# Desarrollo de la VPN

## Configuracion de VPS

### Paso 1 — Instalar dependencias
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
sudo apt install docker docker-compose -y
sudo usermod -aG docker $USER

# Verificar instalación
docker --version
docker-compose --version
````

### Paso 2 — Clonar repositorio

```bash
cd /etc
git clone [<url>](https://github.com/emigodki/back-to-homelab.git)
# Recomiendo renombrar la carpeta wireguard-vps a wireguard y eliminar los demás archivos del repo
cd /wireguard
```

> 💡 **Nota:**
> En el `docker-compose.yml` se define la configuración del servidor y peers (clientes).

#### Generar claves WireGuard

```bash
cd config
umask 077 && sudo sh -c 'wg genkey | tee privatekey | wg pubkey > publickey'
```

### Paso 3 — Correr el script de setup

```bash
cd ..
sudo chmod +x script-vps.sh
sudo bash script-vps.sh
```

### Paso 4 — Configuración del Peer 1 (pivote al Homelab)

```bash
cd config/wg_confs
nano wg0.conf
```

El archivo `wg0.conf` debe contener las llaves privadas y precompartidas.
El peer 1 debe tener la IP de la red del Homelab (ej. `192.168.100.0/24`).

### Paso 5 — Reiniciar el servicio

```bash
docker-compose down
docker-compose up -d
```

#### Obtener configuración del Peer 1

```bash
cd /etc/wireguard/config/peer1
cat peer1.conf
```

---

## Configuración de Servidor local (HomeLab)

### Paso 1 — Instalar dependencias

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
sudo apt install docker docker-compose -y
sudo usermod -aG docker $USER

# Verificar instalación
docker --version
docker-compose --version
```

#### Configurar Homelab como cliente del VPS

```bash
cd /etc
git clone https://github.com/emigodki/back-to-homelab.git
# Recomiendo renombar la carpeta wireguard-homelab a wireguard y eliminar los demás archivos del repo
cd /wireguard/config/wg_confs
nano wg0.conf
```

Ejemplo de `wg0.conf`:

```
[Interface]
PrivateKey = <PRIVATE_KEY>
Address = 10.69.69.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <PUBLIC_KEY_DEL_VPS>
PresharedKey = <KEY>
Endpoint = <IP_PUBLICA_DEL_VPS>:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### Paso 2 — Correr el script de setup

```bash
cd /etc/wireguard
sudo chmod +x script.sh
sudo bash script.sh
```

---

## Configurar un cliente Windows

### Paso 1 — Obtener configuración del Peer 2

```bash
cd /etc/wireguard/config/peer2
cat peer2.conf
```

### Paso 2 — Configurar en WireGuard para Windows

1. Descargar e instalar WireGuard.
2. Añadir un túnel vacío.
3. Pegar el contenido de `peer2.conf`.
4. Guardar y activar el túnel. ✅

---

## Configurar en un dispositivo móvil

Mostrar el QR para el Peer 3:

```bash
docker exec -it wireguard /app/show-peer 3
```

1. Instalar la app **WireGuard** en el móvil.
2. Seleccionar ➕ → **Crear desde código QR**.
3. Escanear el QR mostrado en el VPS.
4. Asignar un nombre y activar el túnel. 📱

---

# Comprobación de estado

Ver estado de los peers:

```bash
# VPS
docker exec wireguard wg show

# Home Server
docker exec wireguard-client wg show
```

Si la VPN funciona, verás transferencia de datos en ambos lados.

---

# Resolución de problemas

1. **Revisar firewall**

   ```bash
   sudo ufw status
   ```
2. **Verificar interfaz WireGuard**

   ```bash
   ip a show wg0
   ```
3. **Revisar tablas de enrutamiento**

   ```bash
   ip route
   ```
4. **Consultar logs**

   ```bash
   # VPS
   docker logs wireguard

   # Home server
   docker logs wireguard-client
   ```
5. **Reiniciar servicios**

   ```bash
   cd /etc/wireguard
   docker-compose down
   docker-compose up -d
   ```

```

---

👉 ¿Quieres que además te prepare un **diagrama en ASCII/Markdown** de la topología (VPS ↔ HomeLab ↔ Clientes) para que quede más visual en el README, o prefieres mantenerlo puro texto?
```
