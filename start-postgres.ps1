
param(
    [string]$containerName="pg",
    [string]$pgPassword='P@ssword1',
    [string]$initializationScript="./dbdefinition.sql",
    [int]$localPort=5432
)
if(test-path $initializationScript) {
    $initializationPath = resolve-path $initializationScript
}
docker run --name $containerName -v "$($initializationPath):/docker-entrypoint-initdb.d/init.sql" -e POSTGRES_PASSWORD=$pgPassword -d -p "$($localPort):5432" postgres:alpine | write-host

# Make sure that the database came up ok
# Check 1 - is the container up and running
start-sleep -Seconds 2
$containersNamedPg = @(docker ps -f name=$containerName)
$pgContainerExists = ($containersNamedPg.length -gt 1)
if($pgContainerExists -eq $false) {
    write-error "$containerName isn't up...why?"
    return -1;
}

# Check 2 - make sure you can query it
$rows = docker exec pg psql -U postgres -c "\l"
if($rows.count -le 3) {
    write-error "This doesn't smell right - not enough databases listed"
    return -1;
}

$connString = "host=localhost;port=$localPort;database=postgres;username=postgres;password=$pgPassword"

Set-Clipboard -Value $connString
write-host "(Connection string copied to clipboard)"
return $connString