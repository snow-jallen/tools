param(
    [string]$containerName="pgadmin",
    [int]$localPort=5005,
    [string]$loginEmail="admin@snow.edu",
    [string]$loginPassword='P@ssword1'
)
docker run -d  --name $containerName -p "$($localPort):80" -e PGADMIN_DEFAULT_EMAIL=$loginEmail -e PGADMIN_DEFAULT_PASSWORD=$loginPassword dpage/pgadmin4
write-host "Starting up pgadmin..."
start-sleep -seconds 5
start-process "http://localhost:$localPort"
