function global:CheckEnvVars($DebeExistir, $varList)
{
  $Errores = 0;
  foreach ($aux in $varlist)
  {
	$a = [environment]::GetEnvironmentVariable($aux);
    if ($DebeExistir -eq $True -and (-not $a))
	{
		$Errores++;
		$color="red"
	} else
	{
		$color="green" 
	}
	Write-host -ForeGroundColor $color -NoNewLine $aux
	Write-Host " ="$a
  }
  
  if ($Errores -gt 0)
  {
	throw "Hay variables de entorno sin definir";
  }
}

function global:CheckFilesExist($FileList)
{
	foreach ($aux in $FileList)
	{
		$Existe = Test-Path $aux
		if (-not $Existe)
		{ throw "El archivo $aux no existe"};
	}
}

function global:CheckDirectoriesExist($DirList)
{
	foreach ($aux in $DirList)
	{
		$Existe = Test-Path $aux
		if (-not $Existe)
		{ throw "El directorio $aux no existe" };
	}
}

function global:GetEnvVarDef($VarToGet, $DefaultValue)
{
	$color = "gray"	
	Write-host -ForeGroundColor $color -NoNewLine $VarToGet
	
	$def = $false;
	$a = [environment]::GetEnvironmentVariable($VarToGet);
	if (-not $a)
	{
		$a = $DefaultValue
		$def = $true;
	}
	
	write-Host -NoNewLine " ="$a 
	
	if ($def -eq $true)
	{
		write-Host -ForeGroundColor gray " (Default)"
	} else
	{
		write-Host
	}
	
	return $a;
}