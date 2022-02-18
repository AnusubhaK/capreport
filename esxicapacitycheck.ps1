$FileName = "D:\PowerShell\ZeroFileSize.txt"
if (Test-Path $FileName) {
  Remove-Item $FileName
}

#Get list of all clusters
$Clusterlist = Get-Cluster

#Loop through each Cluster
$Output = foreach ($Cluster in $Clusterlist)
{

    $ClusterName = $Cluster.Name

    #Get host and loop through each of them
    $hostlist=Get-Cluster -Name $ClusterName | Get-VMHost
    foreach ($hostobj in $hostlist)
    {
        $FreeDisk = (Get-Datastore -VMHost $hostobj | Where-Object {$_.Extensiondata.Summary.MultipleHostAccess -eq $True} | Select FreeSpaceGB) 
        $TotalCPUMhz = Get-VMHost $hostobj | Select CpuTotalMhz 
        $UsedCPUMhz = Get-VMHost $hostobj | Select CpuUsageMhz 
        $NumCPU = Get-VMHost $hostobj | Select NumCpu
        $FreeCpuCore = [math]::Round((($TotalCPUMhz.CpuTotalMhz - $UsedCPUMhz.CpuUsageMhz)/1000)/($TotalCPUMhz.CpuTotalMhz/(1000*$NumCPU.NumCpu)),0)
        $TotalMemoryGB = Get-VMHost $hostobj | Select MemoryTotalGB 
        $UsedMemoryGB = Get-VMHost $hostobj | Select MemoryUsageGB 
        $FreeMemoryGB = [math]::Round(($TotalMemoryGB.MemoryTotalGB - $UsedMemoryGB.MemoryUsageGB),0)

        #Write-Host $ClusterName, "`t" $hostobj.Name, "`t" $FreeDisk.FreeSpaceGB, $TotalCPU.NumCpu, $FreeMemoryGB
        New-Object -TypeName PSObject -Property @{
            ClusterName = $ClusterName
            HostName = $hostobj.Name
            FreeCPUCore = $FreeCpuCore
            FreeMemoryGB = $FreeMemoryGB
            FreeSpaceGB = [math]::Round($FreeDisk.FreeSpaceGB,0)
        }
        Select-Object ClusterName, HostName, FreeCPUCore, FreeMemoryGB, FreeSpaceGB
    }
}
$Output | Export-Csv C:\GPoutput.csv -Append -NoTypeInformation -UseCulture
