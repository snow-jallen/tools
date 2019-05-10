
param(
    [string]$containerName="pg",
    [string]$pgPassword='P@ssword1',
    [string]$initializationScript="./dbdefinition.sql",
    [int]$localPort=5432
)
$initializationPath = resolve-path $initializationScript
docker run --name $containerName -v "$($initializationPath):/docker-entrypoint-initdb.d/init.sql" -e POSTGRES_PASSWORD=$pgPassword -d -p "$($localPort):5432" postgres:alpine | write-host

$connString = "host=localhost;port=$localPort;database=postgres;username=postgres;password=$pgPassword"

Set-Clipboard -Value $connString
write-host "(Connection string copied to clipboard)"
return $connString