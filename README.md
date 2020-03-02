# QuickCopy
PowerShell script that 7-Zips and then transfers a directory and contents via BITS to a remote Windows box

## SYNOPSIS
Recursively compresses a directory of files and subdirectories to a  7-zipped archive.  Copies via BITS to the specified server.

## Version
Version 0.01/02-MAR-2020 by Geoff Gariepy (geoff@gariepy.dev)


## SYNTAX

C:\Users\geoffg\Documents\PowerShell\QuickCopy.ps1 [[-SourceDir] <String>] [-TargetServerDrive] <String> [[-TargetDir] <String>] [-FileName] <String> [<CommonParameters>]


## DESCRIPTION
The QuickCopy.ps1 script recursively compresses all of the files and subdirectories in the current directory, then uploads the 7-zipped archive to a remote server.

Assumes that the 7-Zip archiving utility is installed in the standard location of "c:\Program Files\7-Zip\7z.exe"

Visit https://www.7-zip.org to obtain this utility.  You will want the 64-bit version.

If the 7-zip utility is not present, execution will stop with an error message.


#PARAMETERS
    
*-SourceDir <String>*

-SourceDir sets the location from which all files and subdirectories will recursively be compressed and sent.  Defaults to the current directory.

        Required?                    false
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

*-TargetServerDrive <String>*
        
-TargetServerDrive \\Servername\sharename causes the copy of the compressed distribution file to go to that network shared drive.

Note that this parameter needs a UNC-style path; a simple drive-letter mapping will not work.

        Required?                    true
        Position?                    2
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

*-TargetDir <String>*
    
-TargetDir is the folder on the target server's file share to which the archive will be copied.

By default, it deposits the compressed distribution file in a root \tmp directory.

It will create the target directory if it does not already exist.

        Required?                    false
        Position?                    3
        Default value                tmp
        Accept pipeline input?       false
        Accept wildcard characters?  false

*-FileName <String>*
    
-FileName is the name given to the 7-zipped archive file that is transferred to the remote machine.

The .7z filename extension is appended to the value you pass in.

e.g. -FileName Code will be saved as Code.7z on the remote machine.

Note that any file by the same name will be overwritten on the target server if it already exists.

        Required?                    true
        Position?                    4
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

*<CommonParameters>*
    
This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable,    OutBuffer, PipelineVariable, and OutVariable. For more information, see about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

None. You cannot pipe objects to QuickCopy.ps1


## OUTPUTS

QuickCopy.ps1 shows the progress of the compression routine and the upload to the server.


## Examples

*EXAMPLE 1*

    PS C:\>.\QuickCopy.ps1 -TargetServerDrive '\\server\share' -Filename Files

This compresses the files in the current directory (and subdirectories, if any) then launches a BITS file transfer to the \\server\share\tmp directory on the remote server. 

The file in the remote directory (default directory is 'tmp' unless specified with -TargetDir) will be named 'Files.7z'

Note the target directory will be created by the script if necessary, and if it already exists with p any existing file by the same name will be overwritten if your user account has permissions.


*EXAMPLE 2*

    PS C:\>.\QuickCopy.ps1 -TargetServerDrive '\\server\share' -Filename Files -SourceDir c:\Stuff

This recursively compresses the files and subdirectories in the C:\Stuff directory and saves it to the target server as \\server\share\Files.7z
