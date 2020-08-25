#
# Tools.ssh
#
# Utility functions para SSH
#
$global:SSHOptions = "-o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=nul -o BatchMode=yes"
#
# MakeSSHCredentials:
#	Devuelve un objeto con las credenciales SSH.
#

function global:MakeSSHCredentials($server, $username, $privatekeyfile)
{
	if (!($server))
	{
		throw "MakeSSHCredentials. Server no puede estar vacio"
	}
	$obj = New-object psobject;
	Add-Member -InputObject $obj -MemberType NoteProperty -Name server -Value $server
	Add-Member -InputObject $obj -MemberType NoteProperty -Name username -Value $username
	Add-Member -InputObject $obj -MemberType NoteProperty -Name identity -Value $privatekeyfile
	return $obj	
}

# 
# Transfiere un archivo via scp
#
function Global:EnviarSSH($credentials, $archivo, $srcpath, $dstpath)
{	
	# Resuelve los valores a partir de las credenciales
	$Identity = $credentials.identity;
	$userName = $credentials.UserName;
	$server = $credentials.Server;		
	
	$cmd = "scp $SSHOptions -i $Identity $srcPath/$archivo $userName@$server"+":"+"$dstpath/$archivo"	
	if ($Verbose){
		write-host -foreground cyan "SCP: $cmd"
	}
	invoke-expression $cmd
	if (!($LastExitCode -eq 0)){
		throw "Error. Outgoing file transfer failed. ExitCode: $LastExitCode"
	} else
	{
		if ($Verbose){
			write-host -foreground green "Outgoing file transfer OK ($archivo)"
		}
	}
}

function global:RecibirSSH($credentials, $archivo, $srcpath, $dstpath)
{
	write-host "DEBUG: RecibirSSH: Credentials:$Credentials Archivo:$Archivo srcPath:$SrcPath DstPath:$DstPath"
	write-host "DEBUG(2): CurPath:" (Get-Location).Path
	# Resuelve los valores a partir de las credenciales
	$Identity = $credentials.identity;
	$userName = $credentials.UserName;
	$server = $credentials.Server;
	
	$cmd = "scp $SSHOptions -i $Identity $userName@$server"+":"+"$srcPath/$archivo $dstPath/$archivo"
	if ($Verbose){
		write-host -foreground cyan "SSH $cmd"
	}
	invoke-expression $cmd
	if (!($LastExitCode -eq 0)){
		throw "Error. Incoming file transfer failed. ExitCode: $LastExitCode"
	} else
	{
		if ($Verbose)
		{
			write-host -foreground green "Incoming file transfer OK ($archivo)"
		}
	}
}


function global:EjecutarSSH($credentials, $comando){
	
	# Resuelve los valores a partir de las credenciales
	$Identity = $credentials.identity;
	$userName = $credentials.UserName;
	$server = $credentials.Server;
	
	$cmd = "ssh $SSHOptions -i $Identity $userName@$server $comando";
	if ($Verbose){
		write-host -foreground cyan $cmd
	}
	invoke-expression $cmd
	if (!($LastExitCode -eq 0)){
		throw "Error. Command failed. cmd=$cmd"
	} else
	{
		if ($Verbose){
			write-host -foreground green "Remote command OK"
		}
	}
}

function global:TestPathSSHPWSH($credentials, $path)
{
	EjecutarSSH $Credentials "pwsh -command Set-Location $path"
}

# Vieja. No se usa mas. No es portable.
function global:TestPathSSH_old($credentials, $path)
{	
	EjecutarSSH $Credentials "cmd.exe /c cd $path"
}
