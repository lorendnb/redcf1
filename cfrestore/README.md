# Backup de Redmine

## Topología

1. REDMINE. Redmine corriendo dentro de un container Linux. 
2. HOST. Host Linux con Docker corriendo el container de Redmine.
3. CLIENTE. Máquina cliente Windows que saca el backup.

## Generación de claves SSH

```cmd.exe
ssh-keygen -t rsa -b 2048 -f backupkey
```

Con la instrucción de arriba se generan dos claves. Una pública y una privada.
La pública tiene extensión .pub y la privada no tiene extensión.

### IMPORTANTE
La **clave pública** debe ser agregada en el host destino dentro de authorized_keys dentro del directorio .ssh para el usuario que se use para sacar los backups.

## Ejemplo de Uso

En la máquina cliente (cmd.exe):
```cmd
set SSH_USER=docker
set SSH_SERVER=192.168.1.70
set SSH_PRIVATEKEYFILE=backupkey
powershell -command .\backup_redmine.ps1 
```

## Funcionamiento

1. El script lee la confituración de las variables de entorno.
2. Se conecta via SSH al host que contiene el docker que corre el container de redmine (sin password).
3. Ejecuta un script que realiza el backup dentro del host.
4. Trae la carga (el backup) a la máquina local.
5. Loguea Cominezo, Fin y Errores. en el Event-Log de Windows.

## Requisitos en el cliente (Windows):

1. Powershell
2. EventLog. Tiene que haber un event source creado con el nombre "Backups" o lo que indique la variable de entorno BKP_EVENTLOGSOURCE. Para esto se provee un script crear_event_source.ps1

3. Cliente SSH (win32) instalado. 

4. Las siguientes variables de entorno son usadas para hacer backups de redmine.

Variable | Significado
-----------|------------
BKP_EVENTLOGSOURCE | Event Source para eventlog.
BKP_OUTPUTDIR | Directorio de salida del backup. Valor por defecto: "salida"
BKP_WORKDIR | Directorio de trabajo del backup. Valor por defecto: "backup_redmine"
BKP_SCRIPTFILE | Script File de backup (Corre en el host). Valor por defecto: "./backup_redmine.sh"
BKP_PAYLOADDIR | directorio de payload en el server. Valor por defecto:  "./backup_redmine/data/"
BKP_PAYLOADFILE| Valor por defecto: "backup_redmine.tar.gz"
SSH_PRIVATEKEYFILE | Apunta al archivo con la clave privada SSH
SSH_USER | Contiene el nombre del usuario SSH.
SSH_SERVER | Es la dirección del server.

5. El directorio de salida debe existir. Si no, da error.

## Requisitos en el servidor (Linux)

1. La clave pública del servidor debe estar incorporada en las authorized_keys del directorio .ssh en el usuario que se use para hacer los backups.
2. Tanto el directorio .ssh como el archivo authorized_keys deben tener los permisos correctos.
3. El usuario tiene que tener los permisos necesarios para correr el script de backup.

## Pruebas
1. El cliente tiene que poder entrar via SSH a la máquina destino
2. El cliente tiene que poder correr el script de backup manualmente.
