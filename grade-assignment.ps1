# grade-assignment

param(
    [string]$root="c:\git",
    [string]$assignmentName,
    [string]$commitUrl,
    [string]$student  
)

$assignmentFolder = (join-path $root $assignmentName);
if((test-path $assignmentFolder -PathType Container) -eq $false){
    new-item $assignmentFolder -ItemType Container
}

if($commitUrl.Contains("/commit")){
    $indexOfCommit = $commitUrl.IndexOf("/commit");
    $repo = $commitUrl.Substring(0,$indexOfCommit);
    $hash = $commitUrl.Substring($indexOfCommit+8);
}
else { # just a repo url
    $repo = $commitUrl
    $hash = $null
}
write-host "Taking $repo @ $hash for $student"

set-location $assignmentFolder
if(test-path $student -PathType Container){
    remove-item $student -Recurse -Force
}
git clone $repo $student
set-location $student
if($hash -ne $null){
    git checkout $hash
}

gci *.sln -Recurse | select-object -First 1 | %{Start-Process $_}