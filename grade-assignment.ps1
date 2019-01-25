# grade-assignment

param(
    [string]$assignmentFolder,
    [switch]$openInVisualStudio,
    [switch]$openInCode,
    [string]$commitUrl,
    [string]$student  
)

if((test-path $assignmentFolder -PathType Container) -eq $false){
    new-item $assignmentFolder -ItemType Container
}

if($commitUrl.Contains("/commit")){
    $indexOfCommit = $commitUrl.IndexOf("/commit");
    $repo = $commitUrl.Substring(0,$indexOfCommit);
    $hash = $commitUrl.Substring($indexOfCommit+8, 20);
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

if($openInVisualStudio) {
    gci *.sln -Recurse | select-object -First 1 | %{Start-Process $_}
}

if($openInCode) {
    code .
}
