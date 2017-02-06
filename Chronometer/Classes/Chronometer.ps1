class Chronometer
{
    [hashtable]$FileMap = @{}
    $Breakpoint = @()

    [void]AddBreakpoint([string[]]$Path, [int[]]$LineNumber)
    {
        foreach($file in (Resolve-Path $Path -ea 0))
        {
            $script = [MonitoredScript]@{Path=$file.Path}
            $lines = $script.SetScript($file)
            if($LineNumber -ne $null)
            {
                $bpLine = $LineNumber
            }
            else 
            {
                $bpLine = (1..$lines)
            }

            $this.fileMap[$file.Path] = $script

            $breakpointParam = @{
                Script = $file
                Line = $bpLine
                Action = {[ScriptProfiler]::RecordExecution( $_) }
            }
            $this.breakPoint += Set-PSBreakpoint @breakpointParam
        }
    }

    [void]ClearBreakpoint()
    {
        if($this.Breakpoint -ne $null -and $this.Breakpoint.count -gt 0)
        {
            Remove-PSBreakpoint -Breakpoint $this.Breakpoint
        }
        
    }

    [void] AddExecution([hashtable]$Execution)
    {
        $script = $Execution.Breakpoint.Script
        if($this.FileMap.ContainsKey($script))
        {
            # Each script tracks it's own execution times
            $this.FileMap[$script].AddExecution($Execution)
        }
    }

    [MonitoredScript[]] GetResults()
    {
        foreach($node in $this.FileMap.Values)
        {
            $node.PostProcessing()
        }
        return $this.FileMap.Values
    }
}
