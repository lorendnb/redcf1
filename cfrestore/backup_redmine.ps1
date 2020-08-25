$ErrorActionPreference = "stop"
Invoke-Expression (Join-Path $PSScriptRoot "bkp_utils.ps1");
Invoke-Expression (Join-Path $PSScriptRoot "Tools.ssh.ps1");
$eventLogSource = GetEnvVarDef "BKP_EVENTLOGSOURCE" "BackupRedmine"
$BKP_ITEM = GetEnvVarDef "BKP_ITEM" "Redmine"
$msg = "Backup $BKP_ITEM" + ": Comienzo de backup"
# Write-EventLog -LogName Application -Source $eventLogSource -EntryType Information -Message $msg -EventId 1;
try {
    CheckEnvVars True ("SSH_PRIVATEKEYFILE", "SSH_USER", "SSH_SERVER");
    if (!(Test-Path $ENV:SSH_PRIVATEKEYFILE)) {
        throw "Error. File $ENV:SSH_PRIVATEKEYFILE does not exist";
    }

    # Directorio de salida en la máquina cliente
    $OUTPUTDIR = GetEnvVarDef "BKP_OUTPUTDIR" "salida"

    # Directorio de trabajo en el host
    $WORKDIR = GetEnvVarDef "BKP_WORKDIR" "backup_redmine"

    # Script de backup en el host. Relativo al directorio de trabajo
    $SCRIPTFILE = GetEnvVarDef "BKP_SCRIPTFILE" "./backup_redmine.sh"

    # Directorio de payload.
    $PAYLOADDIR = GetEnvVarDef "BKP_PAYLOADDIR" "./backup_redmine/data/";

    # Archivo con el payload
    $PAYLOADFILE = GetEnvVarDef "BKP_PAYLOADFILE" "backup_redmine.tar.gz";

    # Chequea que exista el directorio de salida
    CheckDirectoriesExist($OUTPUTDIR);

    $Credentials = MakeSSHCredentials $ENV:SSH_SERVER $ENV:SSH_USER $ENV:SSH_PRIVATEKEYFILE

	# Envia la ultima versión del script de backup.
	EnviarSSH $credentials "backup_redmine.sh" . $WORKDIR
		
    # NOTA: Tiene que desactivar el control de errores porque algunas escrituras a stderr de warnings.
    # Pasa con algunso warnings del mysql.
    $Comando = "'cd $WORKDIR;chmod +x $SCRIPTFILE;$SCRIPTFILE' 2>error.txt"
    write-host -foreground cyan $comando
    $ErrorActionPreference = "Continue"
    EjecutarSSH $Credentials $Comando
    $ErrorActionPreference = "Stop"

    RecibirSSH $credentials $PAYLOADFILE $PAYLOADDIR $OUTPUTDIR

    # Calcula el nombre completo del archivo nomenclado
    $FechaActual = (Get-Date).ToString("yyyyMMdd");
    $CompName = $Env:COMPUTERNAME
    $Nomenclado = "PROD_BACKUP_REDMINE_$FechaActual"+"_$CompName" + ".zip";
    $ZipFileName = $Nomenclado


    #
    # Realiza el .zip nomenclado borrando el archivo recibido.
    #
    $CurLoc = Get-Location
    try {
        # Se mueve al directorio de salida
        Set-Location $OUTPUTDIR

        $CmdZip = "7z a -sdel $ZipFileName $PAYLOADFILE"
        invoke-Expression $CmdZip
        if (-not ($LastExitCode -eq 0)) {
            throw "Error ejecutando comando $cmdZip"
        }
    } finally
    {
        Set-Location $CurLoc
    }

    # Registra en el eventLog.
    $msg = "Backup $BKP_ITEM" + ": El backup ha finalizado OK";
	# Write-EventLog -LogName Application -Source $eventLogSource -EntryType Information -Message $msg -EventId 2;

	write-host -foreground green "El backup se completo de manera exitosa"
}
catch {
    $ex = $_;
    $errorCapture = "";
    if (Test-Path error.txt) {
        $errorCapture = Get-Content error.txt
    }
    $msg = "Backup $BKP_ITEM.Error: " + $ex.ToString();
    if ($errorCapture) {
        $msg = "$msg Error Capture: $errorCapture";
    }
    # Write-EventLog -LogName Application -Source $eventLogSource -EntryType Error -Message $msg -EventId 51;
    Write-Host
    Write-host -foreground red "Error: $ex"
    if ($errorCapture) {
        Write-host -foreground red "Error Capture: $errorCapture"
    }
    Exit 2
}
