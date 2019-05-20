param(
    [string]$containerName="pg",
    [string]$dumpFile="dbdefinition.sql",
    [string]$dbName="postgres"
)

docker exec $containerName pg_dump -U postgres -d $dbName | out-file $dumpFile -Encoding utf8