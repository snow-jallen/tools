# Steps:
param (
    [Parameter(mandatory=$true)][Alias("projectName")]
    [string]$name,
    [string]$solutionName,
    # Specifies a path to one or more locations.
    [Parameter(Mandatory=$false,
               Position=0,
               ParameterSetName="ParameterSetName",
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               HelpMessage="Path to place the solution folder")]
    [Alias("PSPath")]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $filePath
)

$toolsDir = split-path $MyInvocation.InvocationName -resolve

if($solutionName -eq "") {
    $solutionName = $name
}

#Step 0 - Preconditions
$containersNamedPg = @(docker ps -f name=pg)
$pgContainerExists = ($containersNamedPg.length -gt 1)
if($pgContainerExists -eq "pg") {
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
#change path if option set
if ($filePath){
    Set-Location -Path $($filePath)
}

#Step 1 - Create new website & solution from template
write-progress "Create new website & solution from template"
dotnet new sln --name $solutionName --output $solutionName
set-location $solutionName
dotnet new mvc --auth Individual --name $name --output $name
dotnet sln add $name
set-location $name

#Step 2 - Delete existing migrations
write-progress "Delete existing migrations"
remove-item .\Data\Migrations\ -Recurse -Force

#Step 3 - Add Npgsql package
write-progress "Add Npgsql package"
dotnet add package npgsql.entityframeworkcore.postgresql

#Step 4 - Change startup.cs
write-progress "Change startup.cs"
(get-content .\Startup.cs).Replace("UseSqlite","UseNpgsql") | set-content .\Startup.cs

#Step 5 - Start up database container
write-progress "Start up database container"
$startScript = join-path $toolsDir "start-postgres.ps1"
$connectionString = & $startScript
write-host "Connection String: $connectionString"

#Step 6 - Replace connection string
write-progress "Replace connection string"
$json = get-content .\appsettings.json | ConvertFrom-Json
$json.ConnectionStrings.DefaultConnection = $connectionString
$json | convertto-json | set-content .\appsettings.json

#Step 7 - Update the database
write-progress "Update the database"
dotnet ef migrations add InitialVersion
dotnet ef database Update

#Step 8 - Dump the database
write-progress "Dump the database"
$dumpScript = join-path $toolsDir "dump-postgres.ps1"
& $dumpScript

#Step 9 - Create git repo
write-progress "Create git repo"
dotnet tool install -g dotnet-gitignore
set-location ".."
dotnet gitignore
git init
git add .
git commit -m "Initial commit"

#Step 10 - Start the solution
write-progress "Starting solution..."
start-process "$solutionName.sln"