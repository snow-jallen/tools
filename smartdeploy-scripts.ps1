# Update the SmartDeploy Client Service
\\smartdeploy\public\sdclientsetup.msi /quiet ;
start-sleep 120 ;
& 'C:\Program Files\SmartDeploy\ClientService\SDClientService.exe'
 


# Make sure SmartDeploy Client Service is running on all computers.
Import-Csv .\143.csv,.\lib.csv,.\Commons.csv,.\142.csv | %{invoke-command -ComputerName engr6hcp5s3.ad.snow.edu -ScriptBlock {
  $s = get-service sdclient*; if($s.status -eq "Running"){$s.status} else {$s | start-service; "Started service."}  
}}

 


# Update visual studio on every machine, individually.
Import-Csv .\143.csv,.\lib.csv,.\Commons.csv,.\142.csv | %{invoke-command -ComputerName engr6hcp5s3.ad.snow.edu -ScriptBlock {
  dotnet tool update -g dotnet-vs;
  $Env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  vs update --all
}}