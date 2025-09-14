$temp_folder = Join-Path -Path $Env:Temp -ChildPath "sameboy"
[System.IO.Directory]::CreateDirectory($temp_folder)
$ProgressPreference = 'SilentlyContinue'

# Visual Studio Build Tools
$vcvars_location = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if ([System.IO.File]::Exists($vcvars_location)) {
    Write-Output "Visual Studio tools already exist"
} else {
    Write-Output "installing Visual Studio tools"
    $vc_url = "https://aka.ms/vs/17/release/vs_buildtools.exe"
    $vc_temp_installer = Join-Path -Path $temp_folder -ChildPath "vc-installer.exe"
    Invoke-WebRequest $vc_url -OutFile $vc_temp_installer
    Start-Process -FilePath $vc_temp_installer -Wait -ArgumentList "--passive", "--add Microsoft.VisualStudio.Workload.VCTools;includeOptional;includeRecommended"
}

# SDL2
$sdl2_temp_location = Join-Path -Path $temp_folder -ChildPath "sdl"
if ([System.IO.Directory]::Exists($sdl2_temp_location)) {
    Write-Output "SDL2 already downloaded"
} else {
    Write-Output "Downloading SDL2"
    $sdl2_url = "https://github.com/libsdl-org/SDL/releases/download/release-2.32.10/SDL2-devel-2.32.10-VC.zip"
    $sdl2_temp_zip = Join-Path -Path $temp_folder -ChildPath "sdl2.zip"
    Invoke-WebRequest $sdl2_url -OutFile $sdl2_temp_zip
    Expand-Archive $sdl2_temp_zip -DestinationPath $sdl2_temp_location
}

# Git
$git_temp_location = Join-Path -Path $temp_folder -ChildPath "git"
if ([System.IO.Directory]::Exists($git_temp_location)) {
    Write-Output "Git already downloaded"
} else {
    Write-Output "Downloading 7Zip extractor..."
    #   Install 7zip module
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Scope CurrentUser -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Set-PSRepository -Name 'PSGallery' -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted
    Install-Module -Scope CurrentUser -Name 7Zip4PowerShell -Force

    Write-Output "Downloading Git"
    $git_url = "https://github.com/git-for-windows/git/releases/download/v2.51.0.windows.1/PortableGit-2.51.0-64-bit.7z.exe"
    $git_temp_7z = Join-Path -Path $temp_folder -ChildPath "git.7z"
    Invoke-WebRequest $git_url -OutFile $git_temp_7z

    #   Extract 7zip file
    Expand-7Zip -ArchiveFileName $git_temp_7z -TargetPath $git_temp_location
    Remove-Item -Path $git_temp_7z
}

#RGBDS
$rgbds_temp_location = Join-Path -Path $temp_folder -ChildPath "rgbds"
if ([System.IO.Directory]::Exists($rgbds_temp_location)) {
    Write-Output "rgbds already downloaded"
} else {
    Write-Output "Downloading rgbds..."
    $rgbds_url = "https://github.com/gbdev/rgbds/releases/latest/download/rgbds-win64.zip"
    $rgbds_temp_zip = Join-Path -Path $temp_folder -ChildPath "rgbds.zip"
    Invoke-WebRequest $rgbds_url -OutFile $rgbds_temp_zip
    Expand-Archive $rgbds_temp_zip -DestinationPath $rgbds_temp_location
}

#Make
$make_temp_location = Join-Path -Path $temp_folder -ChildPath "make"
if ([System.IO.Directory]::Exists($make_temp_location)) {
    Write-Output "make already downloaded"
} else {
    Write-Output "Downloading make..."
    $make_url = "https://sourceforge.net/projects/ezwinports/files/make-4.4.1-without-guile-w32-bin.zip/download"
    $make_temp_zip = Join-Path -Path $temp_folder -ChildPath "make.zip"
    # The default UA for Invoke-WebRequest makes SourceForge behave as it's a browser.
    Invoke-WebRequest $make_url -UserAgent "Wget" -OutFile $make_temp_zip
    Expand-Archive $make_temp_zip -DestinationPath $make_temp_location
}

$batch_file_path = Join-Path -Path $temp_folder -ChildPath "run.bat"
Write-Output "Generating..."
@"
call "$vcvars_location"
set lib=%lib%;$("$sdl2_temp_location\SDL2-2.32.10\lib\x64")
set include=%include%;$("$sdl2_temp_location\SDL2-2.32.10\include")
set path=%path%;$rgbds_temp_location
set path=%path%;$("$git_temp_location\usr\bin")
$("$make_temp_location\bin\make.exe clean")
$("$make_temp_location\bin\make.exe sdl")
"@ > $batch_file_path
$cmd = Get-Command -Syntax cmd
Start-Process -WorkingDirectory $(Get-Location) -Wait $cmd -ArgumentList "/C", $batch_file_path