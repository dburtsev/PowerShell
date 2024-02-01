# Install-Module -Name AWS.Tools.Installer -Force -SkipPublisherCheck -Scope Allusers
# Install-AWSToolsModule -Name AWS.Tools.Glue -Scope AllUsers -Force -CleanUp
# Install-Module -Name ImportExcel -Scope AllUsers
$ErrorActionPreference="Stop"
Set-PSDebug -Strict

Import-Module ImportExcel
Import-Module -Name AWS.Tools.Glue

$Env:AWS_ACCESS_KEY_ID=""
$Env:AWS_SECRET_ACCESS_KEY=""
$Env:AWS_SESSION_TOKEN=""

# create result table
[System.Data.DataTable]$table = New-Object System.Data.DataTable 'GlueJobs'
[System.Data.DataColumn]$newcol = New-Object System.Data.DataColumn ('Name', [string]); $table.Columns.Add($newcol)
$newcol = New-Object System.Data.DataColumn ('LastRun', [System.DateTime]); $table.Columns.Add($newcol)
$newcol = New-Object System.Data.DataColumn ('Workflows', [string]); $table.Columns.Add($newcol)
$newcol = New-Object System.Data.DataColumn ('ExecutionTime', [int]); $table.Columns.Add($newcol)
$newcol = New-Object System.Data.DataColumn ('ScriptLocation', [string]); $table.Columns.Add($newcol)
$newcol = New-Object System.Data.DataColumn ('sparkUIPath', [string]); $table.Columns.Add($newcol)
$newcol = New-Object System.Data.DataColumn ('TempDir', [string]); $table.Columns.Add($newcol)
#get a list of existing jobs
[string[]]$jobs = Get-GLUEJobNameList -Region us-east-1 
#[string[]]$jobs = 'gl_jb_deploy'
foreach($job in $jobs) {
    Write-Host $job
    [Amazon.Glue.Model.Job]$jb = Get-GLUEJob -JobName $job -Region us-east-1 
    [Nullable[DateTime]]$lastRun = $null
    [System.Nullable[int]]$ExecutionTime = $null
    try {
        $lastRun = Get-GLUEJobRunList -JobName $job -Select "JobRuns.StartedOn" | Measure-Object -Maximum | Select-Object -expand Maximum 
        $ExecutionTime = Get-GLUEJobRunList -JobName $job -Select "JobRuns.ExecutionTime" | Select-Object -first 1
    }
    catch {
        Write-Host "no run date"
    }
    [System.Data.DataRow]$row = $table.NewRow()
    $row.Name = $job
    if ($null -ne $LastRun) { $row.LastRun = $LastRun }
    if($null -ne $ExecutionTime) { $row.ExecutionTime = $ExecutionTime }
    $row.ScriptLocation = Split-Path -Parent $jb.Command.ScriptLocation
    [System.Collections.Generic.Dictionary[[string], [string]]]$defArgs = $jb.DefaultArguments
    if ($null -ne $defArgs['--spark-event-logs-path']) { $row.sparkUIPath = $defArgs["--spark-event-logs-path"] }
    $row.TempDir = $defArgs["--TempDir"]
    $table.Rows.Add($row) 
}
# get a list of existing workflows
[string[]]$wfs = Get-GLUEWorkflowList -Region us-east-1 
foreach ($wf in $wfs) {
    Write-Host $wf
    [Amazon.Glue.Model.Workflow]$Workflow = Get-GLUEWorkflow -Name $wf -Region us-east-1 -IncludeGraph $true
    [System.Collections.Generic.List[Amazon.Glue.Model.Node]]$Nodes = $Workflow.Graph.Nodes
    foreach ($node in $Nodes) { 
        if($node.Type.Value -eq 'JOB') {
            #Write-Host $node.Name
            [System.Data.DataRow[]]$filteredRow = $table.Select("Name='" + $node.Name +"'");
            if ($filteredRow.Count -eq 0) { continue } # job was deleted
            [string]$newVal = $filteredRow[0]["Workflows"].ToString() + $wf + ','
            $filteredRow[0]["Workflows"] = $newVal
        }
    }
}
#delete file if exist
[string]$outfile = Join-Path -Path $PSScriptRoot -ChildPath 'GlueTimePath.xlsx'
if (Test-Path $outfile) { Remove-Item $outfile }
$table |Select-Object -Property  * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | Export-Excel $outfile -TableStyle Medium16 -AutoSize -FreezeTopRow

Write-Host Finished at (Get-Date -Format g)
cmd /c 'pause'