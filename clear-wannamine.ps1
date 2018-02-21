function Clear-WannaMine
{
<#
.Synopsis
   This script is to remove WannaMine malware from computer
.DESCRIPTION
   Functions purpose is to remove wannaMine from computer. You can use LogOnly switch to only look in to the objects that this function would remove. 
   Default log path is c:\temp\wannamine, which is created if it does not exist.
   Script will close all other existing powershell processes. I highly recommend that you run logonly first.
.EXAMPLE
   Clear-WannaMine -LogPath c:\temp
   
   Command will try to clear the computer and makes log files to path c:\temp
.EXAMPLE
   Clear-WannaMine -LogPath c:\temp -LogOnly

   Command will look in to the objects and makes log to path c:\temp
.EXAMPLE
   Clear-WannaMine -LogOnly

      Command will look in to the objects and makes log to path c:\temp\wannamine
.EXAMPLE
   Clear-WannaMine

   Command will try to clear the computer and makes log files to path c:\temp\wannamine
.Notes
   Author
   Aapeli Hietikko 2018.02.20
   aapeli@hietikko.net
#>

    [CmdletBinding()]
    Param
    (
        # Set path for the Log location
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $LogPath='c:\temp\wannamine',

        # Use this to log all the objects that this script would remove
        [Parameter(Mandatory=$false)]
        [switch]
        $logOnly
    )

    Begin
        {
        Write-output "spinning up the clear-wannamine"
        $date = (get-date -Format "yyyyMMdd-HHmmss" )
        
        if (-not (test-path $LogPath)) {
            
            new-item -Path $LogPath -ItemType Directory -Confirm:$false -Force -Verbose
            
            }
        
        get-process powershell | where {$_.id -ne $PID} | Stop-Process -Confirm:$false -Verbose 
        
        }
    Process
        {

        #Logging
        $commandlineObjects      = Get-WMIObject -Namespace root\Subscription -Class CommandLineEventConsumer -ErrorAction SilentlyContinue | select *
        $FilterToConsumerBinding = Get-WMIObject -Namespace root\Subscription -Class __FilterToConsumerBinding  -ErrorAction SilentlyContinue| select *
        $EventFilter             = Get-WMIObject -Namespace root\Subscription -Class __EventFilter  -ErrorAction SilentlyContinue| select *
        $Win32_Services          = Get-WMIObject -Namespace root\default -Class Win32_Services -ErrorAction SilentlyContinue | select *
        
        get-process powershell | where {$_.id -ne $PID} | Stop-Process -Confirm:$false -Verbose

        switch ($logOnly.IsPresent) {
        
            $true {
                
                    $commandlineObjects       | out-file "$LogPath\$($date)_logging_CommandLineEventConsumer.txt" 
                    $FilterToConsumerBindings | out-file "$LogPath\$($date)_logging_FilterToConsumerBinding.txt"
                    $EventFilters             | out-file "$LogPath\$($date)_logging_EventFilter.txt"
                    $Win32_Services           | out-file "$LogPath\$($date)_logging_Win32_Services.txt"

                    } #True
        
            $false {
                    
                    Write-Output "starting cleanup"


                    if ($commandlineObjects) {
                        foreach ($commandlineObject in $commandlineObjects) {
                            
                            $commandlineObjects | out-file "$LogPath\$($date)_PreClean_CommandLineEventConsumer.txt" 
                            Get-WMIObject -Namespace root\Subscription -Class CommandLineEventConsumer -Filter "Name= '$($commandlineObject.name)'" | Remove-WMIObject -Verbose
                            
                            }
                    }

                    if ($FilterToConsumerBindings) {

                        foreach ($FilterToConsumerBinding in $FilterToConsumerBindings) {
                            
                            $FilterToConsumerBindings | out-file "$LogPath\$($date)_PreClean_FilterToConsumerBinding.txt"
                            Get-WMIObject -Namespace root\Subscription -Class __FilterToConsumerBinding -Filter "Name= '$($FilterToConsumerBinding.name)'" | Remove-WMIObject -Verbose
                            
                            }
                    }

                    if ($EventFilters) {
                        foreach ($EventFilter in $EventFilters) {
                            
                            $EventFilters | out-file "$LogPath\$($date)_PreClean_EventFilter.txt"
                            Get-WMIObject -Namespace root\Subscription -Class __EventFilter -Filter "Name= '$($EventFilter.name)'" | Remove-WMIObject -Verbose
                            
                            }
                    }
                    
                    if ($Win32_Services) {

                        $Win32_Services | out-file "$LogPath\$($date)_PreClean_Win32_Services.txt"
                        Get-WMIObject -Namespace root\default -Class Win32_Services | Remove-WMIObject -Verbose
                        
                        }

                    $commandlineObjects      = Get-WMIObject -Namespace root\Subscription -Class CommandLineEventConsumer  -ErrorAction SilentlyContinue| fl commandlinetemplate, name, workingdirectory, __path, __namespace
                    $FilterToConsumerBinding = Get-WMIObject -Namespace root\Subscription -Class __FilterToConsumerBinding  -ErrorAction SilentlyContinue| fl *
                    $EventFilter             = Get-WMIObject -Namespace root\Subscription -Class __EventFilter  -ErrorAction SilentlyContinue| fl __namespace,path,query,name
                    $Win32_Services          = Get-WMIObject -Namespace root\default -Class Win32_Services -ErrorAction SilentlyContinue | fl *

                    $commandlineObjects       | out-file "$LogPath\$($date)_PostClean_CommandLineEventConsumer.txt" 
                    $FilterToConsumerBindings | out-file "$LogPath\$($date)_PostClean_FilterToConsumerBinding.txt"
                    $EventFilters             | out-file "$LogPath\$($date)_PostClean_EventFilter.txt"
                    $Win32_Services           | out-file "$LogPath\$($date)_PostClean_Win32_Services.txt"

                } #Default
        
            } # End switch

        }
    End
        {
        Write-output "Clear-Wannamine is finished. Read logs from $LogPath"
        }
}
