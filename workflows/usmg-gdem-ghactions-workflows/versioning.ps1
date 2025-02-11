param (
[string] $APP_VERSION,
[string]$RepoPath,
[string]$versionFile
)
 Write-Host "$APP_VERSION"
 Write-Host "$RepoPath"
 Write-Host "$versionFile"

$versionMatch =  Select-String -Path $versionFile  -Pattern 'AssemblyVersion\("([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"\)' |  ForEach-Object { $_.Matches | ForEach-Object { $_.Groups[1].Value }}
 Write-Host "$versionMatch"
    if ($versionMatch) {
              $env:APP_VERSION = $versionMatch
              $env:APP_VERSION1 = $versionMatch
              Write-Host "App Version: $env:APP_VERSION"
              $replacement1 = ".${env:GITHUB_RUN_NUMBER}"
              $env:APP_VERSION = $env:APP_VERSION -replace '\.[0-9]+$', $replacement1
              Write-Host "final version: $env:APP_VERSION"
           }else {
            throw "unable to extract Assembly Version from $versionFile "
          }
Write-Host "Updating version strings to: $env:APP_VERSION"
Write-Host "Running Get-Date command ...."
$COPYRIGHT_YEAR = (Get-Date).Year
Write-Host "$COPYRIGHT_YEAR"
#
# Updates the VersionInfo file itself in the root folder with the build number and copyright year.
#
 Get-ChildItem -Path "$RepoPath" -Filter $versionFile | ForEach-Object {
     $fileName = $_.FullName;
     $COPYRIGHT_YEAR = (Get-Date).Year;
     (Get-Content $fileName) -replace 'AssemblyVersion\(.*?\)', "AssemblyVersion(`"$env:APP_VERSION`")" | Out-File -FilePath $fileName;
     (Get-Content $fileName) -replace 'AssemblyFileVersion\(.*?\)', "AssemblyFileVersion(`"$env:APP_VERSION`")" | Out-File -FilePath $fileName;
     (Get-Content $fileName) -replace 'AssemblyCopyright\("(.*)\d{4}(.*)"\)', "AssemblyCopyright(`"`$1 $COPYRIGHT_YEAR`$2`")" | Out-File -FilePath $fileName;
}

$content1 = Get-Content -Path "$RepoPath\$versionFile"
Write-Host "File Content"
Write-Output $content1


# Retrieve the copyright statement in order to make it consistent across all projects.
#
$copyrightStatement = (Select-String -Path "$RepoPath/$versionFile" 'AssemblyCopyright\("(.*)"\)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value })
Write-Host "Using the following copyright statement: $copyrightStatement"
#
# Update any non-SDK projects' AssemblyInfo.cs files
#
    $replacement = "AssemblyCopyright(`"$copyrightStatement`")";
    Get-ChildItem -Recurse -Path $RepoPath -Filter AssemblyInfo.cs | ForEach-Object {
                 $fileName = $_.FullName;
                 (Get-Content $fileName) -replace 'AssemblyVersion\(.*?\)', "AssemblyVersion(`"$env:APP_VERSION`")" | Out-File -FilePath $fileName;
                 (Get-Content $fileName) -replace 'AssemblyFileVersion\(.*?\)', "AssemblyFileVersion(`"$env:APP_VERSION`")" | Out-File -FilePath $fileName;
                 (Get-Content $fileName) -replace 'AssemblyCopyright\("(.*?)\d{4}(.*?)"\)', "AssemblyCopyright(`"`$1 $COPYRIGHT_YEAR`$2`")" | Out-File -FilePath $fileName;
                 $content2 = Get-Content -Path "$fileName"
                 Write-Host "File Content"
                 Write-Output $content2
    }
 #
 # Update the PackageVersion field in each file
#
Get-ChildItem -Recurse -Path $RepoPath -Filter *.csproj | ForEach-Object {
            $fileName = $_.FullName;
            (Get-Content $fileName) -replace '<ApplicationVersion>.*</ApplicationVersion>', "<ApplicationVersion>$env:APP_VERSION</ApplicationVersion>" | Out-File -FilePath $fileName;
            (Get-Content $fileName) -replace '<AssemblyVersion>.*</AssemblyVersion>', "<AssemblyVersion>$env:APP_VERSION</AssemblyVersion>" | Out-File -FilePath $fileName;
            (Get-Content $fileName) -replace '<FileVersion>.*</FileVersion>', "<FileVersion>$env:APP_VERSION</FileVersion>" | Out-File -FilePath $fileName;
            (Get-Content $fileName) -replace '<PackageVersion>.*</PackageVersion>', "<PackageVersion>$env:APP_VERSION</PackageVersion>" | Out-File -FilePath $fileName;
            (Get-Content $fileName) -replace '<ProductVersion>.*</ProductVersion>', "<ProductVersion>$env:APP_VERSION</ProductVersion>" | Out-File -FilePath $fileName;
            (Get-Content $fileName) -replace '<Version>.*</Version>', "<Version>$env:APP_VERSION</Version>" | Out-File -FilePath $fileName;
            (Get-Content $fileName) -replace '<Copyright>.*</Copyright>', "<Copyright>$copyrightStatement</Copyright>" | Out-File -FilePath $fileName;
            $content = Get-Content -Path "$fileName"
            Write-Host "File Content"
            Write-Output $content
            }
#
# Update the copyright statement in any *.nuspec files.
# It's not necessary to update the version -- Octopack will take care of that.
#
Get-ChildItem -Recurse -Path $RepoPath -Filter *.nuspec | ForEach-Object {
$fileName = $_.FullName;
(Get-Content $fileName) -replace '<copyright>.*</copyright>', "<copyright>$copyrightStatement</copyright>" | Out-File -FilePath $fileName;
(Get-Content $fileName) -replace '<Version>.*</Version>', "<Version>$env:APP_VERSION</Version>" | Out-File -FilePath $fileName;
$content3 = Get-Content -Path "$fileName"
Write-Host "File Content"
Write-Output $content3
}
