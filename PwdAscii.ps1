# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
# Found a bug? Email to Dmitriy.Burtsev@cyber.nyc.gov

$ErrorActionPreference="Stop"
Set-PSDebug -Strict
CHCP 1252 # Set active console Code Page to West European Latin

do
{
$job = Read-Host -Prompt " 1 String to ASCII`n 2 ASCII to string`n 0 Exit`n" 
}
until(($job -eq "1") -or ($job -eq "2") -or ($job -eq "0"))

if ($job -eq "0") { exit 0 }1

[int]$i = 1
[int]$j = 0
[string]$hStr = [string]::Empty
[string]$pwd_string = [string]::Empty
[System.Text.StringBuilder]$sb = New-Object -TypeName System.Text.StringBuilder
if ($job -eq "1")
{
    $pwd_string = Read-Host -Prompt "Password?" -MaskInput
    foreach($c in $pwd_string.ToCharArray())
    {
        $x = [byte][char]$c
        Write-Host "$i " $x
        $i++
    }
    $hStr = "{0:### ### ### ###}" -f $pwd_string.GetHashCode()
    Write-Host "The hash code for password is $hStr"
}
else 
{
    do
    {
        $chr = Read-Host -Prompt "ASCII code for letter number $i"
        # is it ASCII code?
        if($chr -ne '')
        {
          [bool]$success = [System.Int32]::TryParse($chr, [ref]$j)
          if ($success)
          {
             if (($j -gt 32) -and ($j -le 255)) 
             {
                [void]$sb.Append([System.Text.Encoding]::ASCII.GetString($chr))
             }
             else {
                 Write-Warning "ASCII code should be between 32 and 255, got $chr"
                 continue
             }
          }
          else {
              Write-Warning "$chr is not a ASCII code"
              continue
          }
        }

        
        $i ++
    }
    while ($chr -ne '')  
    $pwd_string = $sb.ToString()
    $hStr = "{0:### ### ### ###}" -f $pwd_string.GetHashCode()
    Write-Host ("The password is $pwd_string" + [Environment]::NewLine + "The hash code for password is $hStr")
}