# Steps:
param (
    [Parameter(mandatory=$true)][Alias("projectName")]
    [string]$name,
    [string]$parentFolder=".",
    [string]$solutionName
)

function write-step($logMessage)
{
    write-host ""
    write-host "*****************************************************************"
    write-host "***   $logMessage"
    write-host "*****************************************************************"
    write-host ""
}

$toolsDir = split-path $MyInvocation.InvocationName -resolve

if($solutionName -eq "") {
    $solutionName = $name
}

$parentFolder = resolve-path $parentFolder;
write-step "Creating $solutionName\$name in $parentFolder"
set-location $parentFolder

#Step 0 - Preconditions
$containersNamedPg = @(docker ps -f name=pg)
$pgContainerExists = ($containersNamedPg.length -gt 1)
if($pgContainerExists) {
    write-host "A container named 'pg' already exists.  Should I kill it?" -foreground Red
    $ans = read-host
    if($ans.tolower()[0] -eq 'y') {
        docker rm pg -f
    } else {
        return;
    }
} 
#check if docker running
$dockerRunning = docker run --rm alpine echo $((40+2))
if ($dockerRunning -ne 42){
    Write-Error "Docker desktop not running"
    return
}

write-step "Create new website & solution from template"
dotnet new sln --name $solutionName --output $solutionName
set-location $solutionName
dotnet new mvc --auth Individual --name $name --output $name
dotnet sln add $name
set-location $name

write-step "Delete existing migrations"
remove-item .\Data\Migrations\ -Recurse -Force

write-step "Delete sqlite database file from template"
remove-item .\app.db

write-step "Add Npgsql package"
dotnet add package npgsql.entityframeworkcore.postgresql

write-step "Change startup.cs"
(get-content .\Startup.cs).Replace("UseSqlite","UseNpgsql") | set-content .\Startup.cs

write-step "Start up database container"
$startScript = join-path $toolsDir "start-postgres.ps1"
$connectionString = & $startScript
write-host "Connection String: $connectionString"

write-step "Replace connection string"
$json = get-content .\appsettings.json | ConvertFrom-Json
$json.ConnectionStrings.DefaultConnection = $connectionString
$json | convertto-json | set-content .\appsettings.json

write-step "Update the database"
dotnet ef migrations add InitialVersion
dotnet ef database Update

write-step "Dump the database"
$dumpScript = join-path $toolsDir "dump-postgres.ps1"
& $dumpScript

write-step "Create git repo"
$gitignoreToolInstalled = (dotnet tool list -g | Where-Object {$_.contains("gitignore")} | measure-object).count -eq 1
if($gitignoreToolInstalled -eq $false){
    dotnet tool install -g dotnet-gitignore
}
set-location ".."
dotnet gitignore
git init
git add .
git commit -m "Initial commit"

write-step "Starting solution..."
start-process "$solutionName.sln"