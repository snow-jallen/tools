param(
    [string]$containerName="pg",
    [string]$dumpFile="dbdefinition.sql"
)

docker exec $containerName pg_dump postgres -U postgres | out-file $dumpFile -Encoding utf8