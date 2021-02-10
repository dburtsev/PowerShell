# Dmitriy Burtsev
# Got ideas from # https://sushihangover.blogspot.com/2013/03/powershell-gzip-gz-compress-and.html
#

$null = Add-Type -AssemblyName System.Windows.Forms
function GZipFile {
param (
        [Alias("PSPath")][parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string]$srcName,
        [Alias("NewName")][parameter(mandatory=$false,ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)][string]$destName
    )
Process { 
if ([IO.File]::Exists($srcName))
{
    Write-Verbose "Reading from: $srcName"
    if ($destName.Length -eq 0) {
        $destName = -Join ($srcName, '.gz')
    }
}
else {
    Write-Error -Message "$srcName is not a valid path/file"
    return
}

if (Test-Path -Path $destName -PathType Leaf -IsValid) {
    Write-Verbose "Compressing to: $destName"
} else {
    Write-Error -Message "$destName is not a valid path/file"
    return
}

[IO.FileStream]$inputF = New-Object System.IO.FileStream ($srcName), ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
[IO.FileStream]$outputF = New-Object System.IO.FileStream ($destName), ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
[IO.Compression.GzipStream]$gzipStream = New-Object System.IO.Compression.GzipStream ($outputF), ([IO.Compression.CompressionMode]::Compress)

try {
    $inputF.CopyTo($gzipStream);
    }
finally {
    Write-Verbose "Closing streams and newly compressed file"
    $gzipStream.Close();
    $outputF.Close();
    $inputF.Close();
    $destName = [string]::Empty    
    }
}
}
function UnGZipFile {
    param (
            [Alias("PSPath")][parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string]$srcName,
            [Alias("NewName")][parameter(mandatory=$false,ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)][string]$destName
        )
Process {        
if ([IO.File]::Exists($srcName))
    {
        Write-Verbose "Reading from: $srcName"
        if ($destName.Length -eq 0 ) {
            $destName = Join-Path -Path ([IO.Path]::GetDirectoryName($srcName)) -ChildPath ([IO.Path]::GetFileNameWithoutExtension($srcName))
        }
    }
else {
        Write-Error -Message "$srcName is not a valid path/file"
        return
    }
    
if (Test-Path -Path $destName -PathType Leaf -IsValid) {
        Write-Verbose "Creating Decompressed File: $destName"
    } else {
        Write-Error -Message "$destName is not a valid path/file"
        return
    }
    
[IO.FileStream]$inputF = New-Object System.IO.FileStream ($srcName), ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
[IO.FileStream]$outputF = New-Object System.IO.FileStream ($destName), ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
[IO.Compression.GzipStream]$gzipStream = New-Object System.IO.Compression.GzipStream ($inputF), ([IO.Compression.CompressionMode]::Decompress )
    
try {
    $gzipStream.CopyTo($outputF);
    }
finally {
    Write-Verbose "Closing streams and newly decompressed file"
    $gzipStream.Close();
    $outputF.Close();
    $inputF.Close(); 
    $destName = [string]::Empty   
    }
}
}

$UserInput = Read-Host -Prompt "1 - gzip one file `n`r2 - gzip whole directory`n`r3 - decompress one file`n`r0 - Exit"

if(@('1','3') -contains $UserInput) {
    [System.Windows.Forms.OpenFileDialog]$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
    $FileBrowser.Multiselect = $false
    $FileBrowser.CheckFileExists = $true
    if($UserInput -eq '1') {
        $FileBrowser.filter = "All files (*.*)| *.*"      
    }
    else {
        $FileBrowser.filter = "GZip files (*.gz)| *.gz"      
    }
    $result = $FileBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    if ($result -eq [Windows.Forms.DialogResult]::OK){
        if($UserInput -eq '1') {
            GZipFile ($FileBrowser.FileName)
        }
        else {
        UnGZipFile ($FileBrowser.FileName)
        }    
    }
    else {
        exit 0
    }
}

if($UserInput -eq '2') {
    [System.Windows.Forms.FolderBrowserDialog]$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = 'Select the folder containing the data'
    $result = $FolderBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    if ($result -eq [Windows.Forms.DialogResult]::OK){
        Get-ChildItem -Path $FolderBrowser.SelectedPath -File -Recurse -Exclude *.gz | Select -ExpandProperty FullName | GZipFile -Verbose
    }
    else {
        exit 0
    }
}
#UnGZipFile 'D:\Work\GZip\eula.1028.txt.gz' -verbose #'D:\Work\GZip\eula.1028.txt'
