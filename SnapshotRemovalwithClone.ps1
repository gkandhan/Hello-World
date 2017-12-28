<#
.SYNOPSIS
    CloneVM - Clones VMWare Virtual Machines and delete snapshots.
.DESCRIPTION
    This script creates clone of a running virtual machines and delete snapshots
.NOTES
    File Name: SnapshotRemovalwithClone.ps1
    Author: Kandhan Guruswamy
    Requires: Powershell v2 and above with PowerCLI
    Created:  12/27/2017
    Modified: 12/28/2017
.LINK

.EXAMPLE
C:\PS>.\SnapshotRemovalwithClone.ps1
Description
-----------
Clones virtual machines as per input text file that contains VCSA and VM Names.

.PARAMETER ComputerName
    
.PARAMETER Credential
    The Credential to use. One time credentials entered to Get-Credential
#>

#Function to clone VMware virtual machines
function CloneVM ($VM) 
{
    $datee = get-date -format d
    $VMClone = New-VM -Name $VM-Clone-$datee -VM $VM -VMHost ($VMName | get-vmhost | select Name).Name
    if ($VMClone) { $CloneStatus = "Cloned" }
    else { $CloneStatus = "Failed" }
  return $CloneStatus 
}

#Function to delete virtual machine snapshots
function deletesnapshot ($VM)
{
  $snapshot = $null
  $SnapStatus = "No snapshots found"
  $snapshot = Get-Snapshot -VM $VM
  if ($snapshot -ne $null) { 
    Remove-Snapshot -Snapshot $snapshot -RemoveChildren -Confirm:$false
    if ($?) { $SnapStatus = "Snapshots deleted" }
    else { $SnapStatus = "Snapshots failed to delete" } }
  return $SnapStatus
}

o

#Main Program to delete snapshots and clone VMs
$outfile = "D:\Kandhan\Scripts\SnapStatus.csv"
$infile = get-content D:\Kandhan\Scripts\VMs.txt
$ErrorActionPreference = "SilentlyContinue"
$row = 1
$Cred = Get-Credential
foreach ($line in $infile) 
{
  Clear-Host
  $cluster = $VM = $VMPS = $Snapshot = $CloneStatus = $Status = $Null
  $VMStatus = @()
  $VCconnect = connect-viserver -Server $line -Credential $Cred
  if ($VCconnect) 
  {
    $VMs = Get-VM
    if ($VMs) 
    {
      foreach ($VM in $VMs) 
      {
        $Snapshot = $CloneStatus = $Null
        Write-Progress -Status "Working on $VM" -Activity "Snapshot Removal and VM cloning in progress, please wait..."
	$cluster = ($VM | get-cluster).Name
        if ($VM.PowerState -eq "PoweredOn") 
        {
           write-host "working"
          $Snapshot = deletesnapshot $VM.Name
          $CloneStatus = CloneVM $VM.Name
        }
#        else { $Status = "VM Powered Off" }
        $VMStatus += AddObject $line $cluster $VM.Name $VM.PowerState $Snapshot $CloneStatus $Status
      }
    }
    else { $Status = "No VMs found" }
    Disconnect-VIServer $intxt1 -Confirm:$false 
  }
  else { $Status = "VCSA connect failed" }
  $VMStatus += AddObject $line $cluster $VM $VMPS $Snapshot $CloneStatus $Status
  $VMStat = $VMStatus | convertto-csv -delimiter "`t" -notypeinformation 
  if ($row -eq 1) 
  {
    $VMStat | Out-file $outfile
    $row++
  }
  else { $VMStat | Select -Skip 1 | out-file -append $outfile }
}
Write-Host "Activity Completed"