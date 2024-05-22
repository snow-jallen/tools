[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$server,
    [int]$port=5432,
    [parameter(Mandatory=$true)]
    [string]$database,
    [string]$user="postgres",
    [parameter(Mandatory=$false)]
    [string]$password,
    [parameter(Mandatory=$true)]
    [string]$localFolder,
    [parameter(Mandatory=$true)]
    [string]$backupName,
    [Parameter(Mandatory=$false)]
    [string]$schema="*"
)

if($password -eq $null) {
    $ss = read-host "Enter your password" -AsSecureString
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
}
docker run --rm -e PGPASSWORD=$password -v "$($localFolder):/usr/backupoutput" -it postgres pg_dump -h $server -p 5432 -U $user -f /usr/backupoutput/$backupName -d $database --schema=$schema

