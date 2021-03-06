param([Hashtable]$options) 


if ($options.ForPublication) {
    return
}

if ($options.Clean) {
    Remove-Item "$home\Documents\WindowsPowerShell\Modules\EZOut" -Recurse
    Remove-Item "$home\Documents\WindowsPowerShell\Modules\Pipeworks" -Recurse
}

$modulePaths = $env:PSModulePath -split ';'

$showUIFound = $false
$ezOutFound = $false
$scripCopFound = $false
$pipeworksFound = $false

$modulesToFind = @{
    EzOut = $false
    ShowUI = $false
    Pipeworks = $false
}

$moduleDownloadUrl = @{
    EzOut = 'http://ezout.start-automating.com/?-GetManifest'
    Pipeworks = 'http://powershellpipeworks.com/Module.ashx?-GetManifest' 
}


$count = 0
foreach ($moduleName in @($modulestoFind.Keys)) {
    $count++
    $perc = $count * 100 / $modulesToFind.Count
    if (Get-Module $moduleName) { continue } 
    Write-Progress "Starting IsePack" "$moduleName" -PercentComplete $perc
    foreach ($mp in $modulePaths) {    
        if (Test-Path "$mp\$moduleName") {
            Import-Module "$mp\$moduleName\$moduleName" -Global 
            $modulesToFind[$moduleName]  = $true
        } elseif ($mp -eq "$home\Documents\WindowsPowershell\Modules") {
            # Go ahead and download them
            Write-Progress "Downloading $moduleName" "From $($moduleDownloadUrl[$moduleName])" -PercentComplete $perc
            $wc = New-Object Net.WebClient
            $tmpZipFile = [IO.Path]::GetTempFileName() + ".zip"
            $url = [uri]$moduleDownloadUrl[$moduleName]            
            $manifest = $wc.DownloadString($url)
            $xmlManifest = [xml]$manifest
            $modulezipUrl = ($xmlManifest.ModuleManifest.Url.Replace("Module.ashx", "").TrimEnd("/")) + 
                "/"+ $xmlManifest.ModuleManifest.Name + 
                "." + $xmlManifest.moduleManifest.Version + ".zip"
            $moduleZipUrl = $moduleZipUrl -ireplace 'Module\.ashx\/', ''
            $wc.DownloadFile($moduleZipUrl, $tmpZipFile)
            Write-Progress "Extracting $moduleName" " " -PercentComplete $perc
            
            $shell = New-Object -ComObject Shell.Application
            $zipContent = $shell.Namespace($tmpZipFile)
            $homeModules = $shell.Namespace("$home\Documents\WindowsPowershell\Modules\")
            $null = $homeModules.CopyHere($zipContent.Items(),(16 -bor 512))
            $tries = 0
            do {
                Start-sleep -seconds 1
                $tries++
                if ($tries -gt 10) {
                    break
                }
            } while (-not (Test-Path "$mp\$moduleName")) 
            
            Import-Module "$mp\$moduleName\$moduleName" -Global 
            $modulesToFind[$moduleName]  = $true
            
        }
    }
}


if ($psVersionTable.PSVersion -eq '2.0') {
    $global:PromptStatus = @({
        $(if (test-path variable:/PSDebugContext) { '[DBG]: ' } else { '' }) + 'PS ' + $(Get-Location) + $(if ($nestedpromptlevel -ge 1) { '>>' }) 
    })
    $defaultPromptHash = "HEYStcKFSSj9jrfqnb9f+A=="
} elseif ($psVersionTable.PSVersion -eq '3.0') {
    $global:PromptStatus = @({
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
    })
    $defaultPromptHash = ""
}
$md5 = [Security.Cryptography.MD5]::Create()
$thePrompt = try { 
    [Text.Encoding]::Unicode.GetBytes((Get-Command -ErrorAction SilentlyContinue prompt | Select-Object -ExpandProperty Definition))
} catch {

}
$thePromptHash = [Convert]::ToBase64String($md5.ComputeHash($thePrompt))

if ($thePRomptHash -and $thePromptHash -eq $defaultPromptHash) #using the default prompt?
{    
    #recommend our own    
<#    function prompt(){    
        # Reset color, for many things can change this
        $Host.UI.RawUI.ForegroundColor = $global:DefaultPromptColor
    
        $promptText = 
            $global:PromptStatus, '>' | 
                ForEach-Object {
                    if ($_ -is [ScriptBlock]) {
                        . $_
                    } else {
                        $_
                    }
                }
                
        
        return "$($promptText -join ' ')"    
    }#>
} else {
    Write-Verbose "Custom Prompt Already Defined, Not Defining One"
} 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmAzhY4/LcuVdNMXsruSJEUUJ
# t1ugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHkrdaJCOM11tF1R
# dabsRFZgEemyMA0GCSqGSIb3DQEBAQUABIIBALI55RDQqCb9OhuW5p/Lr3vmXnOa
# fCBWQwpydG0uacok+CiJrIgyReeyhRsdLbQ2Qa/r7R5QVNUfIgGxgIsntssRJ6MM
# IqWF+VV3CqKj/OY+VieFeqzyoMfBWw1DX7rYf+3K2RvKeSqQKaOmyk0ScSaBSwsr
# yOB8cpfVq1/qGy5r8t/PtwEqLpjafFeb6eqmpnFKwcTjR7KOQe8rGjsw1R8wbK/U
# 7HLEYdnmvTQxz8dr2ReEHePVBjk1b3p10LwVWgPukK+ta7vNnZJRn22kzaTtjlZV
# ovtyhCxQQVHDo+eEg3YV0vmDLXxDHGbBJIYyohlf0tBc6eRXiYPlZmK8Aww=
# SIG # End signature block
