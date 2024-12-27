##############################################
# Purpose: This script will remove unicode chars from text file and send the output to new file
# History:
# 12/27/2024 Dmitriy Burtsev created 
##############################################
$ErrorActionPreference="Stop"
Set-PSDebug -Strict

[System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
# Define the path to the text file
[string]$textFilePath = "" #"C:\Work\DeleteMe\MOCS_GENTAX_PBL_.asc.TXT"
[string]$srcFileEncoding = ""
[string]$newFileEncoding = ""
[string]$textNewFilePath = ""

# Determines a text file's encoding by analyzing its byte order mark (BOM).
# Defaults to ASCII when detection of the text file's endianness fails (No BOM found).
function Get-FileEncoding {
    param([string]$Path)
    # Read the first 4 bytes of the file using a FileStream
    $stream = [System.IO.File]::OpenRead($Path)
    $bytes = New-Object byte[] 4
    $stream.Read($bytes, 0, $bytes.Length) | Out-Null
    $stream.Close()
     # Determine the encoding based on the BOM
     switch ($bytes[0..3] -join " ") {
        "239 187 191" { "UTF-8 with BOM" }
        "255 254 0 0" { "UTF-32 LE (Little Endian)" }
        "0 0 254 255" { "UTF-32 BE (Big Endian)" }
        "255 254"     { "UTF-16 LE (Little Endian)" }
        "254 255"     { "UTF-16 BE (Big Endian)" }
        default       { 
            # If no BOM, assume another encoding
            "Unknown or No BOM (possibly UTF-8 without BOM or ANSI)" 
        }
    }   
}

[System.Windows.Forms.OpenFileDialog]$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = "C:"
 $OpenFileDialog.filter = “All files (*.*)| *.*”
 if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
   $textFilePath = $OpenFileDialog.filename
}

$srcFileEncoding = Get-FileEncoding -Path $textFilePath 
$textNewFilePath = Join-Path -Path (Split-Path -Path $textFilePath -Parent ) -ChildPath ("NEW_" + (Split-Path -Path $textFilePath -Leaf))

# Delete new file if exist
if (Test-Path -Path $textNewFilePath) { Remove-Item -Path $textNewFilePath -Force }

$lineNumber = 0

# Read the text file
foreach ($line in [System.IO.File]::ReadLines($textFilePath)) {
        $lineNumber++
        [System.Text.RegularExpressions.MatchCollection]$nonAsciiChars = [regex]::Matches($line, '[^\x00-\x7F]')
        if ($nonAsciiChars.Count -gt 0){
            Write-Output "Line $lineNumber contains non-ASCII character(s) $nonAsciiChars" 
            $line = $line -replace '[^\x00-\x7F]', ' ' 
        }
        if ($lineNumber -gt 1) {  -join([Environment]::NewLine, $line) | Out-File -FilePath $textNewFilePath -Encoding ascii -Append -NoNewline}
        else {$line | Out-File -FilePath $textNewFilePath -Encoding ascii -Append -NoNewline}
    }

Write-Output "Source file $textFilePath encoding $srcFileEncoding"
$newFileEncoding = Get-FileEncoding -Path $textNewFilePath
Write-Output "Destination file $textNewFilePath encoding $newFileEncoding"
pause