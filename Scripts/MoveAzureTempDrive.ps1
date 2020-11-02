﻿configuration MoveAzureTempDrive
{
    param(
		[Parameter(Mandatory)] 
        [string]$TempDriveLetter
    )

    Import-DscResource -ModuleName MoveAzureTempDrive

    Node localhost 
    {

       LocalConfigurationManager 
       {
           RebootNodeIfNeeded = $True
       }      
               
        Script DisablePageFile
        {
        
            GetScript  = { @{ Result = "" } }
            TestScript = { 
               $pf=gwmi win32_pagefilesetting
               #There's no page file so okay to enable on the new drive
               if ($pf -eq $null)
               {
                    return $true
               }
               #Page file is still on the D drive
               if ($pf.Name.ToLower().Contains('d:'))
               {
                    return $false
               }

               else
               {
                    return $true
               }
            
            }
            SetScript  = {
                #Change temp drive and Page file Location 
                gwmi win32_pagefilesetting
                $pf=gwmi win32_pagefilesetting
                $pf.Delete()
                Restart-Computer -Force
            }
           
        }

	   MoveAzureTempDrive MoveAzureTempDrive
       {
		  
		   TempDriveLetter = $TempDriveLetter  
		   
       }
                   SetScript  = {
                	Get-Partition -DriveLetter "D" | Set-Partition -NewDriveLetter "T"
                	$TempDriveLetter = "T"
			$TempDriveLetter = $TempDriveLetter + ":"
			$drive = Get-WmiObject -Class win32_volume -Filter “DriveLetter = '$TempDriveLetter'”
			#re-enable page file on new Drive
			$drive = Get-WmiObject -Class win32_volume -Filter “DriveLetter = '$TempDriveLetter'”
			Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{ Name = "$TempDriveLetter\pagefile.sys"; MaximumSize = 0; }
			Restart-Computer -Force
            }
      
	}
}


