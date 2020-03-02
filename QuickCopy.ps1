#QuickCopy.ps1
# 7-Zip compression and BITS file transfer tool
# Modification History
# GGARIEPY 02-MAR-2020 : Creation

[CmdletBinding()]

Param(
[Parameter(Mandatory=$false)]
[string] 
$SourceDir = "",                

[Parameter(Mandatory=$true)]
[string] 
$TargetServerDrive,             

[Parameter(Mandatory=$false)]
[string] 
$TargetDir = "tmp",             

[Parameter(Mandatory=$true)]
[string] 
$FileName
)

$ErrorActionPreference = 'Stop'
if ($SourceDir -ne "") {
    if (Test-Path $SourceDir) {
        Set-Location $SourceDir
    }
    else {
        Write-Host "Could not find source directory [$SourceDir] on this machine.  Aborting." -ForegroundColor Yellow -BackgroundColor Red
        exit
    }
}
$CurrentDir = get-location
Import-Module BitsTransfer
if (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") {
    set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"  
}
else {
    Write-Host "7-Zip utility not detected on this machine.  Download it from 7-zip.org.  Aborting." -ForegroundColor Yellow -BackgroundColor Red
    exit
}

Clear-Host
Write-Host "QuickCopy.ps1:`n`nCompresses all files and subdirectories`nand transfers the archive to a remote server via BITS`n"
Write-Host "`tSource (root) directory to be archived and copied: [$CurrentDir]"
Write-Host "`tTarget server and share: [$TargetServerDrive]"
Write-Host "`tTarget server directory: [$TargetDir]"
Write-Host "`tArchive file name: [$FileName.7z]"
Write-Host "`n`nPress CTRL-C if any of the above is not what you intended and start over."

# Get credentials to make BITS connection on remote server
$UserName = Read-Host "`n`tEnter a user ID in the form of domain\username >" 
$Password = Read-Host -AsSecureString "`n`tEnter the password for the user $UserName >" 
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $Password

# Compress all files into a 7-Zip archive
Write-Host("...compressing solution files")
sz a "$FileName.7z" -spe -y -bsp0 -bso0 -t7z -xr!"$FileName.7z"

# Establish drive mapping to the target server
Write-Host "...connecting to $TargetServerDrive"
New-PSDrive -Name "P" -PSProvider "FileSystem" -Root $TargetServerDrive -Credential $credential -Verbose:$false -ErrorAction SilentlyContinue -ErrorVariable PSDriveError 

# Handle a bad connection to the server
if ($PSDriveError.Length -gt 1){
    Write-Host "`n`nError Connecting to  $TargetServerDrive" -ForegroundColor Black -BackgroundColor Red

    Write-Host "Error message: $PSDriveError"

    Write-Host("Exiting FileCopy.ps1.  Please determine the correct domain\username, password and/or shared drive, then try again.")
    exit
}

if ((Test-Path -Path "P:\$TargetDir") -eq $false) {
    Write-Host "Did not find a drive named '$TargetDir' on $TargetServerDrive, will attempt to create one."
    New-Item -Path "P:\$TargetDir" -ItemType "directory" -Credential $credential -Confirm
}
    

Write-Host "...copying $FileName.7z to $TargetServerDrive\$TargetDir via BITS transfer"

$bitsxfrprms = @{
                'Source'         =  "$FileName.7z";
                'Destination'    =  "P:\$TargetDir\$FileName.7z";
                'TransferType'   =  'Upload';
                'Description'    =  "Transfer of compressed $FileName.7z archive to $TargetServerDrive\$TargetDir";
                'TransferPolicy' =  'Always';
                'DisplayName'    =  'Uploading Archive'
            }



Start-BitsTransfer @bitsxfrprms
Remove-PSDrive -Name P

<#
.SYNOPSIS 
Recursively compresses a directory of files and subdirectories to a  7-zipped archive.  Copies via BITS to the specified server.
02-MAR-2020 : Geoff Gariepy (geoff@gariepy.dev) : [creation]

.DESCRIPTION
The QuickCopy.ps1 script recursively compresses all of the files and subdirectories in the current directory, 
then uploads the 7-zipped archive to a remote server.

Assumes that the 7-Zip archiving utility is installed in the standard location of "c:\Program Files\7-Zip\7z.exe"

Visit https://www.7-zip.org to obtain this utility.  You will want the 64-bit version.

If the 7-zip utility is not present, execution will stop with an error message.

.PARAMETER SourceDir 
-SourceDir sets the location from which all files and subdirectories will recursively be compressed and sent.  Defaults to the current directory.
  
.PARAMETER TargetServerDrive
-TargetServerDrive \\Servername\sharename causes the copy of the compressed distribution file to go to that network shared drive.  

Note that this parameter needs a UNC-style path; a simple drive-letter mapping will not work.

.PARAMETER FileName
-FileName is the name given to the 7-zipped archive file that is transferred to the remote machine.  

The .7z filename extension is appended to the value you pass in.

e.g. -FileName Code will be saved as Code.7z on the remote machine.

Note that any file by the same name will be overwritten on the target server if it already exists.

.PARAMETER TargetDir
-TargetDir is the folder on the target server's file share to which the archive will be copied.  

By default, it deposits the compressed distribution file in a root \tmp directory.  

It will create the target directory if it does not already exist.

.INPUTS
None. You cannot pipe objects to QuickCopy.ps1

.OUTPUTS
QuickCopy.ps1 shows the progress of the compression routine and the upload to the server.

.EXAMPLE
.\QuickCopy.ps1 -TargetServerDrive '\\server\share' -Filename Files

This compresses the files in the current directory (and subdirectories, if any) then
launches a BITS file transfer to the \\server\share\tmp directory on the remote server.  
The file in the remote directory (default directory is 'tmp' unless specified with -TargetDir) will be named 'Files.7z'

    Note the target directory will be created by the script if necessary, and if it already exists with previously-transferred files and scripts
    any existing file by the same name will be overwritten if your user account has permissions.

.EXAMPLE
.\QuickCopy.ps1 -TargetServerDrive '\\server\share' -Filename Files -SourceDir c:\Stuff

This recursively compresses the files and subdirectories in the C:\Stuff directory and saves it to the 
target server as \\server\share\Files.7z

#>