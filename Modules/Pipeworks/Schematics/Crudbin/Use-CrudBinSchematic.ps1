function Use-CrudBinSchematic
{
    <#
    .Synopsis
        Builds a web application according to a schematic
    .Description
        Use-Schematic builds a web application according to a schematic.
        
        Web applications should not be incredibly unique: they should be built according to simple schematics.        
    .Notes
    
        When ConvertTo-ModuleService is run with -UseSchematic, if a directory is found beneath either Pipeworks 
        or the published module's Schematics directory with the name Use-Schematic.ps1 and containing a function 
        Use-Schematic, then that function will be called in order to generate any pages found in the schematic.
        
        The schematic function should accept a hashtable of parameters, which will come from the appropriately named 
        section of the pipeworks manifest
        (for instance, if -UseSchematic Blog was passed, the Blog section of the Pipeworks manifest would be used for the parameters).
        
        It should return a hashtable containing the content of the pages.  Content can either be static HTML or .PSPAGE                
    #>
    [OutputType([Hashtable])]
    param(
    # Any parameters for the schematic
    [Parameter(Mandatory=$true)][Hashtable]$Parameter,
    
    # The pipeworks manifest, which is used to validate common parameters
    [Parameter(Mandatory=$true)][Hashtable]$Manifest,
    
    # The directory the schemtic is being deployed to
    [Parameter(Mandatory=$true)][string]$DeploymentDirectory,
    
    # The directory the schematic is being deployed from
    [Parameter(Mandatory=$true)][string]$InputDirectory
    )
    
    begin {
        $pages = @{}
    }
    
    process {                                                    
        if (-not ($parameter.Read -and $parameter.Create)) {
            Write-Error "crudbin must include gets and adds"
            return
        }
        
        if ($parameter.RequiresSignup)
        {
            if (-not $manifest.UserTable.Name) {
                Write-Error "If the crudbin requires signup, the manifest must contain a user table"
                return
            }
            
            if (-not $Manifest.UserTable.StorageAccountSetting) {
                Write-Error "No storage account name setting found in manifest"
                return
            }
            
            if (-not $manifest.UserTable.StorageKeySetting) {
                Write-Error "No storage account key setting found in manifest"
                return
            }
        } else {
            if (-not $manifest.Table.Name) {
                Write-Error "Bins must have a table or a user table"
                return
            }
            
            if (-not $Manifest.Table.StorageAccountSetting) {
                Write-Error "No storage account name setting found in manifest"
                return
            }
            
            if (-not $manifest.Table.StorageKeySetting) {
                Write-Error "No storage account key setting found in manifest"
                return
            }
        }
        
        
        
        
        # Data bins let people create, read, update, or remove structed items via several commands.
        
        
                
        
        $crudbinPage = {            
    




if ($pipeworksManifest.UserTable) {
    $userTableParameters = @{
        StorageAccount = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageAccountSetting)
        StorageKey = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageKeySetting)
        TableName = $pipeworksManifest.UserTable.Name
    }
    if (-not $connectedToTable) {    
        $connectedToTable = Get-AzureTable @userTableParameters
    }
}

if ($pipeworksManifest.Table) {
    $tableParameters = @{
        StorageAccount = (Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageAccountSetting)
        StorageKey = (Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageKeySetting)
        TableName = $pipeworksManifest.Table.Name
    }
    if (-not $connectedToTable) {    
        $connectedToTable = Get-AzureTable @tableParameters
    }
}

        
$showCommandOutputIfLoggedIn = {
    param($cmdName, [Hashtable]$CmdParameter = @{}) 
    
    if (-not $session['User'] -and $request.Cookies["$($module.Name)_ConfirmationCookie"]) {
        
        $storageAccount = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageAccountSetting)
        $storageKey = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageKeySetting)
        $confirmCookie= $Request.Cookies["$($module.Name)_ConfirmationCookie"]

        $matchApiInfo = [ScriptBLock]::Create("`$_.SecondaryApiKey -eq '$($confirmCookie.Values['Key'])'")           
        $userFound = 
            Search-AzureTable -TableName $pipeworksManifest.UserTable.Name -StorageAccount $storageAccount -StorageKey $storageKey -Where $matchApiInfo 

        if (-not $userFound) {
            $secondaryApiKey = $session["$($module.Name)_ApiKey"]
            $confirmCookie = New-Object Web.HttpCookie "$($module.Name)_ConfirmationCookie"
            $confirmCookie["Key"] = "$secondaryApiKey"
            $confirmCookie["CookiedIssuedOn"] = (Get-Date).ToString("r")
            $confirmCookie.Expires = (Get-Date).AddDays(-365)                    
            $response.Cookies.Add($confirmCookie)
            $response.Flush()
            
            $response.Write("User $($confirmCookie | Out-String) Not Found, ConfirmationCookie Set to Expire")                                        
            return
        }                                        

        $userIsConfirmed = $userFound |
            Where-Object {
                $_.Confirmed -ilike "*$true*" 
            }
            
        $userIsConfirmedOnThisMachine = $userIsConfirmed |
            Where-Object {
                $_.ConfirmedOn -ilike "*$($Request['REMOTE_ADDR'] + $request['REMOTE_HOST'])*"
            }
                
        if (-not $userIsConfirmedOnThisMachine) {                                                            
                return
        }
         
        $session['User'] = $userIsConfirmedOnThisMachine
        $session['UserId'] = $userIsConfirmedOnThisMachine.UserId


        $secondaryApiKey = "$($confirmCookie.Values['Key'])"                                                                                   

        $partitionKey = $userIsConfirmedOnThisMachine.PartitionKey
        $rowKey = $userIsConfirmedOnThisMachine.RowKey
        $tableName = $userIsConfirmedOnThisMachine.TableName
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('PartitionKey')
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('RowKey')
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('TableName')                    
        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogon -Force -Value (Get-Date)
        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogonFrom -Force -Value "$($Request['REMOTE_ADDR'] + $request['REMOTE_HOST'])"
        $userIsConfirmedOnThisMachine |
            Update-AzureTable -TableName $tableName -RowKey $rowKey -PartitionKey $partitionKey -Value { $_} 
            
        $session['User'] = $userIsConfirmedOnThisMachine                
    }
                             
        
    if ($session['User']) {   
        $loginName = if ($session['User'].Name) {
            $session['User'].Name
        } else {
            $session['User'].UserEmail
        }
        $commandInfo = Get-Command $cmdName        
        & $commandInfo @CmdParameter | Out-HTML
    } else { 
        $loginUrl = if ($pipeworksManifest.Facebook.AppId) {
            "Module.ashx?FacebookLogin=true"
        } else {
            "Module.ashx?join=true"
        }
@"
<div id='loginHolder_For_$cmdName'>    
    
</div>
<script>
    query = '$loginUrl'        
    `$(function() {
        `$.ajax({
            url: query,
            cache: false,
            success: function(data){     
                `$('#loginHolder_For_$cmdName').html(data);
            } 
        })
    })
</script>
"@    
    
    }
    
}

$showCommandInputIfLoggedIn = { param($cmdName) 
    if (-not $session['User'] -and $request.Cookies["$($module.Name)_ConfirmationCookie"]) {
        
        $storageAccount = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageAccountSetting)
        $storageKey = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageKeySetting)
        $confirmCookie= $Request.Cookies["$($module.Name)_ConfirmationCookie"]

        $matchApiInfo = [ScriptBLock]::Create("`$_.SecondaryApiKey -eq '$($confirmCookie.Values['Key'])'")           
        $userFound = 
            Search-AzureTable -TableName $pipeworksManifest.UserTable.Name -StorageAccount $storageAccount -StorageKey $storageKey -Where $matchApiInfo 

        if (-not $userFound) {
            $secondaryApiKey = $session["$($module.Name)_ApiKey"]
            $confirmCookie = New-Object Web.HttpCookie "$($module.Name)_ConfirmationCookie"
            $confirmCookie["Key"] = "$secondaryApiKey"
            $confirmCookie["CookiedIssuedOn"] = (Get-Date).ToString("r")
            $confirmCookie.Expires = (Get-Date).AddDays(-365)                    
            $response.Cookies.Add($confirmCookie)
            $response.Flush()
            
            $response.Write("User $($confirmCookie | Out-String) Not Found, ConfirmationCookie Set to Expire")                                        
            return
        }                                        

        $userIsConfirmed = $userFound |
            Where-Object {
                $_.Confirmed -ilike "*$true*" 
            }
            
        $userIsConfirmedOnThisMachine = $userIsConfirmed |
            Where-Object {
                $_.ConfirmedOn -ilike "*$($Request['REMOTE_ADDR'] + $request['REMOTE_HOST'])*"
            }
                
        if (-not $userIsConfirmedOnThisMachine) {                                                            
                return
        }
         
        $session['User'] = $userIsConfirmedOnThisMachine
        $session['UserId'] = $userIsConfirmedOnThisMachine.UserId


        $secondaryApiKey = "$($confirmCookie.Values['Key'])"                                                                                   

        $partitionKey = $userIsConfirmedOnThisMachine.PartitionKey
        $rowKey = $userIsConfirmedOnThisMachine.RowKey
        $tableName = $userIsConfirmedOnThisMachine.TableName
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('PartitionKey')
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('RowKey')
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('TableName')                    
        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogon -Force -Value (Get-Date)
        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogonFrom -Force -Value "$($Request['REMOTE_ADDR'] + $request['REMOTE_HOST'])"
        $userIsConfirmedOnThisMachine |
            Update-AzureTable -TableName $tableName -RowKey $rowKey -PartitionKey $partitionKey -Value { $_} 
            
        $session['User'] = $userIsConfirmedOnThisMachine                
    }
    
    if ($session['User']) {
        $loginName = if ($session['User'].Name) {
            $session['User'].Name
        } else {
            $session['User'].UserEmail
        }
        $hide = @{}
        if ($pipeworksManifest.WebCommand.$cmdName.HideParameter) {
            $hide["HideParameter"] = $pipeworksManifest.WebCommand.$cmdName.HideParameter
        }
        Request-CommandInput -CommandMetaData (Get-Command $cmdName) -Action "$cmdName/?" @hide
    } else { 
        $loginUrl = if ($pipeworksManifest.Facebook.AppId) {
            "Module.ashx?FacebookLogin=true"
        } else {
            "Module.ashx?join=true"
        }
@"
<div id='loginHolder_For_$cmdName'>    
    
</div>
<script>
    query = '$loginUrl'        
    `$(function() {
        `$.ajax({
            url: query,
            cache: false,
            success: function(data){     
                `$('#loginHolder_For_$cmdName').html(data);
            } 
        })
    })
</script>
"@    
    
    }
}


$editProfileIfLoggedIn = { 
    if ($session['User']) {
        @"
<div id='editProfileHolder'>    
    
</div>
<script>
    query = 'Module.ashx?editProfile=true'        
    `$(function() {
        `$.ajax({
            url: query,
            cache: false,
            success: function(data){     
                `$('#editProfileHolder').html(data);
            } 
        })
    })
</script>
"@
    } elseif ($request.Cookies["$($module.Name)_ConfirmationCookie"]) {
        $out = ""
        
        $out += Write-Link -Caption "Login as $($request.Cookies["$($module.Name)_ConfirmationCookie"]["Email"])?" -Url "Module.ashx?Login=true" |
            New-Region -LayerId "ShouldILogin_For_$cmdName" -Style @{
                'margin-left' = $MarginPercentLeftString
                'margin-right' = $MarginPercentRightString
            }
        $out
    } else { @"
<div id='loginToEditProfile'>    
    
</div>
<script>
    query = 'Module.ashx?join=true'        
    `$(function() {
        `$.ajax({
            url: query,
            success: function(data){     
                `$('#loginToEditProfile').html(data);
            } 
        })
    })
</script>
"@
    }
}



$crudbinParameter = $pipeworksManifest.crudbin



$regionParameters = @{
    Id = 'MainRegion'
    Layer = @{}
    Order = @()    
    AsPopin = $true
    
}


$info = $crudBinParameter.Info


if ($info) {

    foreach ($kv in $info.GetEnumerator()) {
        $part, $row = $kv.Value.Id -split ":"
        $displayName = $kv.Value.DisplayName
        $storageAccount, $storageKey, $tableName = 
            if ($pipeworksManifest.UserTable) {
                Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageAccountSetting
                Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageKeySetting
                $pipeworksManifest.UserTable.Name
            } elseif ($pipeworksManifest.UserTable) {
                Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageAccountSetting
                Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageKeySetting
                $pipeworksManifest.Table.Name
            }
         
        $regionParameters.Layer[$displayName] =    
            Show-WebObject -StorageAccount $storageAccount -StorageKey $storageKey -Table $tableName -Part $part -Row $row 
        $regionParameters.Order += $displayName.Trim()
    }
}


if ($crudBinParameter.EditProfile -and $session['User']) {
    $displayName = $crudBinParameter.EditProfile
    $regionParameters.Layer[$displayName] = & $editProfileIfLoggedIn
    $regionParameters.Order += $displayName.Trim()
}

$creates = $crudBinParameter.Create

foreach ($kv in $creates.GetEnumerator()) {
    $newCmd = Get-Command $kv.Value.Command
    $displayName = $kv.Value.DisplayName
    $regionContent = 
    if ($pipeworksManifest.WebCommand.($newCmd.Name).RequireLogin -or 
        $kv.Value.RequireLogin) {
        
        & $showCommandInputIfLoggedIn ($newCmd.Name) 
    } else {
        Request-CommandInput -CommandMetaData $newCmd.Name -DenyParameter $pipeworksManifest.WebCommand.($newCmd.Name).HideParameter
    }
         
    if ($regionContent) {
        $regionParameters.Layer[$displayName.Trim()] = "$regionContent"
        $regionParameters.Order += $displayName.Trim() 
    }   
    
            
    # If the getter is the default, and there's not already a default layer, make it the default layer
    if ($kv.Value.IsDefault) {
        $regionParameters.Default = $kv.Value.DisplayName
    }
}

# Process getters first
$getters = $crudBinParameter.Read

foreach ($kv in $getters.GetEnumerator()) {
    # If a default handler is present, use this information to populate a content area
        
    $getCmd = Get-Command $kv.Value.Command
    
    if (-not $getCmd) { continue }
    
    
    $getParameters = @{}
    if ($kv.Value.QueryParameter) {   
        
        foreach ($qp in $kv.Value.QueryParameter.GetEnumerator()) {
            
            if ($request[$qp.Key]) {
                $getParameters += @{$qp.Value.Trim()=$request[$qp.Key].Trim()}
            }
            
        }        
        
    }
    
    if ($kv.Value.DefaultParameter) {
        
        foreach ($qp in $kv.Value.DefaultParameter.GetEnumerator()) {
            $getParameters += @{$qp.Key=$qp.Value}                        
        }
    }
    
    $regionContent = if ($getParameters.Count) {
        if ($pipeworksManifest.WebCommand.($getCmd.Name).RequiresLogin -or 
            $kv.Value.RequireLogin) {
            . $showCommandOutputIfLoggedIn ($getCmd.Name) $getParameters | Out-HTML
        } else {            
            & $getCmd @getParameters | Out-HTML
        }
    } else {
        ''
    }
    
    
    
    if ($regionContent) {
        $regionParameters.Layer[$kv.Value.DisplayName] = $regionContent
        $regionParameters.Order += $kv.Value.DisplayName
        # If the getter is the default, and there's not already a default layer, make it the default layer
        if ($kv.Value.IsDefault) {
            $regionParameters.Default = $kv.Value.DisplayName
        }
    }                            
}

$default = 
    if ($Request['Show']) {
        $Request['Show']
    } else {
        ''
    }
    
if ($pipeworksManifest.CrudBin.Order) {
    $regionParameters.Order = $pipeworksManifest.CrudBin.Order
} else {
    $regionParameters.Order =  $regionParameters.Order  | Sort-Object
}

if ($default.Length) {
    $regionParameters.Default = $default
}

$mainContent = 
    New-Region @regionParameters |
        New-Region -Style @{
            'Margin-left'='10%'
            'Margin-Right' = '10%'
            'Text-Align' = 'center'
        }  
        
$lowerLoginButton = if ($pipeworksManifest.UserTable.Name) {
    $loginLink = if ($pipeworks.Facebook.Appid) {
        "Module.ashx?FacebookLogin=true"
    } else {
        "Module.ashx?Login=true"
    }
    Write-Link -Url "$loginLink" -Caption "<span class='ui-icon ui-icon-locked'> Login </span>" |
        New-Region -LayerID LoginButtonLayer -Style @{
            Position = 'Absolute'
            Right = '5px'
            Bottom = '5px'
        }
} else {
    ""
}
    
$lowerLoginButton, $mainContent | 
    New-WebPage -NoCache -Title $module.Name -UseJQueryUI -JQueryUITheme $pipeworksManifest.JQueryUITheme |
    Out-HTML -WriteResponse


        }



        
        $pages["bin.pspage"] = "<|

$crudbinPage
|>"
        $pages["default.pspage"] ="<|
$crudbinPage
|>"     
                
    }
    end {
        $pages
    }
} 

 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyc1FJ7ax0fGvy1dxy6hmqX6j
# yYugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHprvLkjBWvyC22L
# odNpGyiN1vVrMA0GCSqGSIb3DQEBAQUABIIBALfmQyh6N7in6o0OCYpiTNmUXqzV
# aoBN0qB7PHXrQuio7te8pYTbdr9UfbX0ChmF2tj8AMAaLhSfdGMlTzuFNYWvftSU
# PJBrOqSW0bilzP1dlZgZMdbo9cd2fttzX/r6X1KLeutsw2QpFn4osZemtnMeX2BK
# cO32zdsIPgb3ijV+dB/ncgq2x7Ex4KT0ND4zw7wWvjXTdAP8llahQ6SiVZI76O2C
# Q87uMDENGfzD6V7BOpxI1Ow1VlaUIKOoAwQfsVMtkbo3bNutEeoy9hwLU9eVH1yi
# caiNDqKGcbOQ8bMe32tyvAmW+w4kkvB9dDKEOUtZ6UU75tQIU5RFBBgr190=
# SIG # End signature block
