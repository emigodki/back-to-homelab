# Desarrollo de la VPN
## Configuracion de VPS
### Paso 1
##### Instalar dependencias
```bash

# Actualizar paqueterias
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Instalar docker y docker-compose
sudo apt install docker docker-compose -y

# Añadir usuario actual al grupo docker
sudo usermod -aG docker $USER

# Verificar instalación
docker --version
docker-compose --version

```

### Paso 2
##### Clonar repositorio

```bash
cd /etc
git clone <url>
cd /wireguard
```


> [!NOTE] Nota
> En el docker-compose.yml tenemos la configuracion del servidor, ahí se pueden asignar más peers (clientes) para configurar

##### Generar las claves Wireguard
Es importante generar claves privadas y publicas para nuestro servidor
```bash
cd config
umask 077 && sudo sh -c 'wg genkey | tee privatekey | wg pubkey > publickey'
```

### Paso 3
##### Correr el script de setup
```bash
cd ..
sudo chmod +x script-vps.sh
sudo bash script-vps.sh

```

### Paso 4
##### Configuracion del Peer 1 (Que será el pivote al Homelab)

```bash
cd config
cd wg_confs
nano wg0.conf
```

Asi deberíamos tener nuestro wg0.conf
Las partes negras deben tener las llaves privadas y precompartidas (se rellenan solas al correr el script)

Es importante que el peer 1 tenga la ip de la red del homelab server que en mi caso es 192.168.100.0/24

![[Pasted image 20250826142017.png]]

### Paso 5
##### Reiniciar el servicio
```bash
docker-compose down
docker-compose up -d
```

##### Obtener los datos para establecer el Servidor local como cliente peer 1
```bash
cd /etc/wireguard/config/peer1
cat peer1.conf
```

Copiamos el contenido de peer1.conf
## Configuración de Servidor local (HomeLab)
### Paso 1
##### Instalar dependencias
```bash

# Actualizar paqueterias
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Instalar docker y docker-compose
sudo apt install docker docker-compose -y

# Añadir usuario actual al grupo docker
sudo usermod -aG docker $USER

# Verificar instalación
docker --version
docker-compose --version

```
##### Configurar el Homelab como cliente del VPS

```bash
cd /etc
git clone <url>
cd /wireguard
cd /config
cd /wg_confs
nano wg0.conf
```

la estructura del wg0.conf debera ser como esta:
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

Reemplaza los valores `<PRIVATE_KEY> <PUBLIC_KEY_DEL_VPS> <KEY> <IP_PUBLICA_DEL_VPS>` con los que copiaste del peer1.conf en el VPS

Guarda los cambios

### Paso 2
##### Correr el script de set-up
```bash
cd /etc/wireguard
sudo chmod +x script.sh
sudo bash script.sh
```

# Configurar un cliente windows
### Paso 1
En el VPS vamos al directorio con la configuracion de cada peer
```bash
cd /etc/wireguard/config
cd peer2
cat peer2.conf
```

Copiamos el contenido
### Paso 2
Descargamos e instalamos Wireguard para windows
Al abrirlo le daremos en añadir tunel y añadir tunel vacio
![[./assets/Pasted image 20250826144154.png]]

Y pegamos el contenido del peer que acabamos de copiar
![[Pasted image 20250826144338.png]]
Aqui no hace falta editar nada más, solo guardamos y activamos el tunel

# Configurar en un dispositivo movil
Mostramos el QR generado (util para los moviles)

```bash
# En el VPS
docker exec -it wireguard /app/show-peer 3
```

En nuestro dispositivo descargaremos la aplicación de Wireguard

Al abrirla le daremos en el simbolo de "+" y posteriormente "Crear desde código QR"
![[Pasted image 20250826145342.png]]

Escanearemos el codigo QR que arrojó el VPS por la terminal y luego asignamos un nombre
![[Pasted image 20250826145425.png]]

# Comprobación de estado

Para comprobar el estado del VPN en ambos servidores usaremos el siguiente comando:
```bash
# Para el VPS
docker exec wireguard wg show

# Para el Home Server
docker exec wireguard-client wg show

```

Si el VPN funciona correctamente verás lo siguiente en el VPS:
![[Pasted image 20250826143821.png]]

El primer Peer (con la ip 10.69.69.2) tiene transferencia de datos exitosa

Y en el Home Server:
![[Pasted image 20250826143945.png]]

# Resolución de problemas

Si encuentras problemas de conectividad:

1. **Revisa la configuración del firewall** Asegúrate de que el puerto UDP 51820 está abierto en tu VPS:
```bash
sudo ufw status
```

2. **Verifica el estado de la interfaz Wireguard** En ambos lados:

```bash
ip a show wg0
```

3. **Revisa las tablas de enrutamiento**

```bash
ip route
```

4. **Consulta los logs de Wireguard**

```bash
# Para el VPS
docker logs wireguard

# Para el Home server
docker logs wireguard-client
```

5. **Reinicia los servicios Wireguard** 
En el VPS o  Home Server:
```bash
cd /etc/wireguard
docker-compose down
docker-compose up -d
```
