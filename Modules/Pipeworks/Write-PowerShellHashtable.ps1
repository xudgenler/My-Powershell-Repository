function Write-PowerShellHashtable {
    <#
    .Synopsis
        Takes an creates a script to recreate a hashtable
    .Description
        Allows you to take a hashtable and create a hashtable you would embed into a script.
        
        Handles nested hashtables and indents nested hashtables automatically.
    .Parameter inputObject
        The hashtable to turn into a script
    .Parameter scriptBlock
        Determines if a string or a scriptblock is returned
    .Example
        # Corrects the presentation of a PowerShell hashtable
        @{Foo='Bar';Baz='Bing';Boo=@{Bam='Blang'}} | Write-PowerShellHashtable
    .Outputs
        [string]
    .Outputs
        [ScriptBlock]   
    .Link
        about_hash_tables
    #>    
    [OutputType([string], [ScriptBlock])]
    param(
    [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [PSObject]
    $InputObject,

    # Returns the content as a script block, rather than a string
    [Alias('ScriptBlock')]
    [switch]$AsScriptBlock,

    [Switch]$Sort
    )

    process {
        $callstack = @(foreach ($_ in (Get-PSCallStack)) {
            if ($_.Command -eq "Write-PowerShellHashtable") {
                $_
            }
        })
        $depth = $callStack.Count
        if ($inputObject -isnot [Hashtable]) {
            
            $newInputObject = @{
                PSTypeName=@($inputobject.pstypenames)[-1]
            }
            foreach ($prop in $inputObject.psobject.properties) {                
                $newInputObject[$prop.Name] = $prop.Value
            }
            $inputObject = $newInputObject
        }
        
        if ($inputObject -is [Hashtable]) {
            #region Indent
            $scriptString = ""
            $indent = $depth * 4        
            $scriptString+= "@{
"
            #endregion Indent
            #region Include
            $items = $inputObject.GetEnumerator()

            if ($Sort) {
                $items = $items | Sort-Object Key
            }
            

            foreach ($kv in $items) {
                $scriptString+=" " * $indent
                
                $keyString = "$($kv.Key)"
                if ($keyString.IndexOfAny(" _.#-+:;()'!?^@#$%&".ToCharArray()) -ne -1) {
                    if ($keyString.IndexOf("'") -ne -1) {
                        $scriptString+="'$($keyString.Replace("'","''"))'="
                    } else {
                        $scriptString+="'$keyString'="
                    }                    
                } elseif ($keyString) {
                    $scriptString+="$keyString="
                }
                                
                
                
                $value = $kv.Value
                # Write-Verbose "$value"
                if ($value -is [string]) {
                
                    $value = "'"  + $value.Replace("'","''").Replace("’", "’’").Replace("‘", "‘‘") + "'"
                } elseif ($value -is [ScriptBlock]) {
                    $value = "{$value}"
                } elseif ($value -is [switch]) {
                    $value = if ($value) { '$true'} else { '$false' }
                } elseif ($value -is [bool]) {
                    $value = if ($value) { '$true'} else { '$false' }
                } elseif ($value -and $value.GetType -and ($value.GetType().IsArray -or $value -is [Collections.IList])) {
                    $value = foreach ($v in $value) {
                        if ($v -is [Hashtable]) {
                            Write-PowerShellHashtable $v
                        } elseif ($v -is [Object] -and $v -isnot [string]) {
                            Write-PowerShellHashtable $v
                        } else {
                            ("'"  + "$v".Replace("'","''").Replace("’", "’’").Replace("‘", "‘‘") + "'")
                        }
                    }
                    $oldOfs = $ofs 
                    $ofs = ",
$(' ' * ($indent + 4))"
                    $value = "$value"
                    $ofs = $oldOfs
                } elseif ($value -as [Hashtable[]]) {
                    $value = foreach ($v in $value) {
                        Write-PowerShellHashtable $v
                    }
                    $value = $value -join ","
                } elseif ($value -is [Hashtable]) {
                    $value = "$(Write-PowerShellHashtable $value)"
                } else {
                    $valueString = "'$value'" 
                    if ($valueString[0] -eq "'" -and 
                        $valueString[1] -eq "@" -and 
                        $valueString[2] -eq "{") {
                        $value = Write-PowerShellHashtable -InputObject $value                    
                    } else {
                        $value = $valueString
                    }
                    
                }                                
               $scriptString+="$value
"
            }
            $scriptString += " " * ($depth - 1) * 4          
            $scriptString += "}"     
            if ($AsScriptBlock) {
                [ScriptBlock]::Create($scriptString)
            } else {
                $scriptString
            }
            #endregion Include
        }          
   }
}         

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJlY3duA28uF+zZdyyi5ZeYz5
# UmKgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFK96CwSEwFpVwIE0
# G8sbfNAuCAOsMA0GCSqGSIb3DQEBAQUABIIBAH5/enSB2KhXmgJ8XTZMAU72bn9k
# eZDfCuFiJUBFgHKpoGSj9XzsQrx13wOSuKELjSH4SriX+biQ4+dFMJcQ7Xg1nv6t
# W6ufHUf0oPUjDDLaFva3dhdait+v9ET2vPESrcFInxCdq43fYMvsUg7bQVOjxdRJ
# ZDEdTTB1M3xJ+06J3WevYyFt8Vs7xBGyiRZ90r+79xBaKkt58qGeMReotOLwWdU6
# YA7cUjEYrSIjECVdK4Pl8yYn0oxCUpqJihIFrTACkwLrw8KZDHcSAeJzs8okdPOW
# PqrDBunmKHDfyM0IamC6/adMGUtlQMbHaGMs5kRiO0IbwtZYNPSWsUDFaG0=
# SIG # End signature block
