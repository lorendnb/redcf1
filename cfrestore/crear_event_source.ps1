$source = "BackupRedmine" 
if ([System.Diagnostics.EventLog]::SourceExists($source) -eq $false) {
    [System.Diagnostics.EventLog]::CreateEventSource($source, "Application")
}
Write-Host -ForeGroundColor green ($source+" event source OK")
