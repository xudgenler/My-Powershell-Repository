function Use-GallerySchematic
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
    [Parameter(Mandatory=$true)]
    [Hashtable]$Parameter,
    
    # The pipeworks manifest, which is used to validate common parameters
    [Parameter(Mandatory=$true)][Hashtable]$Manifest,
    
    # The directory the schemtic is being deployed to
    [Parameter(Mandatory=$true)][string]$DeploymentDirectory,
    
    # The directory the schematic is being deployed from
    [Parameter(Mandatory=$true)][string]$InputDirectory     
    )
    
    process {
    
        if (-not $Parameter.Collection) {
            Write-Error "No collection found in parameters"
            return
        }
        
        
        
        $requiresTableConnection = 
            $parameter.Collection |
                Where-Object { $_.Partition }
        
        
        $localInventory =
            $parameter.Collection |
                Where-Object { $_.Directory } 
        
        if (-not $localInventory) {
            $requiresTableConnection  = $true
        }
        if ($requiresTableConnection ) {
            if (-not $Manifest.Table.Name) {
                Write-Error "No table found in manifest"
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
        
        $manifest.AcceptAnyUrl = $true
                                        
        
        $anyPage = {
        
        
        
            if ($pipeworksManifest.Table) {
            
                # Pick out the storage account and storage key from the manifest.  If they are not present, the values will be blank.
                $storageAccount = (Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageAccountSetting)
                $storageKey = (Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageKeySetting)                                                           
            }

            #region Get collection metadata
            $CollectionNames  = @()

            
            $Collections = 
                foreach ($CollectionInfo in $pipeworksManifest.Gallery.Collection) {
                    $Collection = New-Object PSObject -Property $CollectionInfo
                    $CollectionNames += $Collection.Name
                    $Collection 
                }
        
            #endregion Get collection metadata
               
                
            
            # Determine relative URL and original URL
            $originalUrl = $context.Request.ServerVariables["HTTP_X_ORIGINAL_URL"]

            $pathInfoUrl = $request.Url.ToString().Substring(0, $request.Url.ToString().LastIndexOf("/"))
            
                
                
            $pathInfoUrl = $pathInfoUrl.ToLower()
            $protocol = ($request['Server_Protocol'].Split("/", [StringSplitOptions]"RemoveEmptyEntries"))[0]  # Split out the protocol
            
            

            $serverName= $request['Server_Name']                     # And what it thinks it called the server
            
            $fullOriginalUrl = $protocol.ToLower() + "://" + $serverName + $request.Params["HTTP_X_ORIGINAL_URL"]
            $fullOriginalUrl = $fullOriginalUrl.ToLower()
            
            $pathInfoUrl = $pathInfoUrl.ToLower()
            $relativeUrl = $fullOriginalUrl.Replace("$pathInfoUrl", "")            
            
            
            if (-not $fullOriginalUrl) {
                "No Original URL"
                return
            }
            
            $pageCss = @{
    "body" = @{
        "line-height" = "160%"
        "padding-top" = "0px"
        "padding-left" = "0px"
        "padding-right" = "0px"
        "padding-bottom" = "0px"
        "margin-top" = "0px"
        "margin-left" = "0px"
        "margin-right" = "0px"
        "margin-bottom" = "0px"
    }
} 
            $ShowThing= {

param([Parameter(Mandatory=$true)][string]$Name,
[string[]]$Caption,
[string[]]$Url,
[string]$FirstColor = "#012456",
[string]$HeaderTextColor = "#fff",
[string]$MainTextColor = "#000000",
[string]$SecondColor = "#010c1d",
[string]$ThirdColor = "#ffffff",
[string]$Thing)
"<h1 style='top:25px;font-variant:normal;font-weight:bold;font-size:24px;margin-bottom:5px;line-height:2em'>$Name</h1>" | 
    New-Region -LayerID MainHeaderContainer -Style @{
        "color" = "$HeaderTextColor"
        "letter-spacing" = "-1px"
        "margin-left" = "17%"
        "padding-right" = "40px"
        "padding-left" = "40px"
        "padding-bottom" = "0px"
        "padding-top" = "0px"
        "min-width" = "480px"
        "max-width" = "960px"
        #"text-shadow" ="0 2px 0 #510000"
    } |
    New-Region -LayerID PageHeader -Style @{
        width = "100%"
        "height" = "80px"
        "background-image" = "none"
        "background-attachment" = "scroll"
        "background-repeat" = "repeat"        
        "background-position-x" = "0%"
        "background-position-y" = "0%"
        "background-origin" = "padding-box"
        "background-clip" = "border-box"
        "background-size" = "auto"
        "background-color" = "$FirstColor"
        "text-align" = "left"
        
    }
    
$count=  0
$urlLinks = foreach ($u in $url) {
    if (-not $u) { continue }
    $c = $caption[$count] 
    New-Object PSObject -Property @{
        Url = $u
        Caption = $c
    }
    $count++
}

if ($urlLinks) {
    $urlLinks = $urlLinks|
        Write-Link -Horizontal -Button -Style @{"padding" = "6px" }
}
$urlLinks|    
    New-Region -LayerID HeaderContainer -Style @{        
        "color" = "$HeaderTextColor"
        "margin-right" = "17%"
        "letter-spacing" = "1.1px"
        "padding" = "4px"
        "min-width" = "350px"
        "max-width" = "960px"
        "font-size" = "xx-small"
        "float" = "right"
    } |
    New-Region -LayerID PageSecondHeader -Style @{
        width = "100%"
        "height" = "40px"
        "background-image" = "none"
        "background-attachment" = "scroll"
        "background-repeat" = "repeat"        
        "background-position-x" = "0%"
        "background-position-y" = "0%"
        "background-origin" = "padding-box"
        "background-clip" = "border-box"
        "background-size" = "auto"
        "background-color" = "$SecondColor"
        "color" = "#fff"
    }    
    
$thing |
    New-Region -LayerID MainContainer -Style @{        
        
        "margin-right" = "auto"
        "margin-left" = "auto"
        "margin-top" = ".5em"
        "letter-spacing" = "-1px"
        "padding-right" = "40px"
        "padding-left" = "40px"
        "min-width" = "350px"
        "max-width" = "960px"
        "font-size" = "medium"
                
        "text-align" = "left"
    } |
    New-Region -LayerID MainContent -Style @{
        width = "66%"
        "height" = "40px"
        "background-image" = "none"
        "background-attachment" = "scroll"
        "background-repeat" = "repeat"        
        "background-position-x" = "0%"
        "background-position-y" = "0%"
        "background-origin" = "padding-box"
        "background-size" = "auto"
        "background-color" = "$ThirdColor"
        "color" = "$mainTextcolor"
        
    } 
    
            
            }
            
            $loadFilesInSet = {
                            
                if ($_.PSIsContainer) { return }
                
                if ($_.Fullname -like '*.psd1') {
                    # Treat as a data file
                    
                    Import-PSData -FilePath $_.fullname -AllowCommand ConvertFrom-Markdown, Write-ScriptHTML, Write-Link, New-Region, New-WebPage, Out-HTML, Add-Member |
                        Add-Member NoteProperty FullName $fullname -Force -PassThru
                } else {
                    $_
                }
            } 
            
            
            $optionalStyleSheet = @{
            
            }
            
            if ($pipeworksManifest.gallery.StyleSheet) {
                $optionalStyleSheet.StyleSheet = $gallery.StyleSheet
            }
            
            
            
            
            $sortSetItems = {
                if ($_.DatePublished) {
                    [DateTime]$_.DatePublished 
                } elseif ($_.Timestamp) {
                    [DateTime]$_.Timestamp
                } elseif ($_.LastWriteTime) {
                    $_.LastWriteTime
                }
            }                         
            
            
            $renderLayers = {
                if ($collection.StyleSheet) {
                    $optionalStyleSheet.StyleSheet = $collection.StyleSheet
                }
                $thingTitle= 
                    if ($itemIdentifier) { 
                        "$($CollectionFriendlyName) | $($itemIdentifier)"
                        $exactMatch = $popouts.Keys | Where-Object { $_ -eq $itemIdentifier }
                        if ($exactMatch) {
                            $Newpopouts = @{}
                            $Newpopouts[$itemIdentifier] = $popouts[$itemIdentifier] 
                            $popOuts = $Newpopouts
                        }
                    } else {
                        "$($CollectionFriendlyName)"
                    }
                    
                    
                
                if ($popouts.Count -gt 1) {
                    if ($Collection.Directory) {
                        $thingHtml = New-Region -LayerID InventoryItems -Order $order -Layer $popouts  -AsPopout
                        & $showThing @colorScheme -Name $thingTitle -Thing $thingHtml |
                            New-WebPage -Title $thingTitle -UseJQueryUI @optionalStyleSheet
                    } elseif ($Collection.Partition) {
                        $thingHtml =  
                            New-Region -LayerID InventoryItems -Order $order -Layer $popouts -LayerUrl $popoutUrls -AsPopout 
                        & $showThing @colorScheme -Name $thingTitle -Thing $thingHtml |
                            New-WebPage -Title $thingTitle  -UseJQueryUI @optionalStyleSheet
                    }
                } else {

                    if ($Collection.Directory) {
                        if ($order) {
                            $exactMatch = @($order -eq $itemIdentifier)
                            
                            if ($exactMatch.Count -eq 1 ) {
                                $name = "$($exactMatch)"
                                $thingHtml = $popouts[$name]                            
                            } else {
                                $thingHtml = "$($popouts[$order])"
                            }                            
                            & $showThing @colorScheme -Name $thingTitle -Thing $thingHtml |
                                New-WebPage -Title $thingTitle -UseJQueryUI @optionalStyleSheet

                        } else {                        
                            
                            #$thingHtml = $popouts[$name]
                            & $showThing @colorScheme -Name $thingTitle -Thing "<h3>Topic $Name not found</h3>" |
                                New-WebPage -Title $thingTitle -UseJQueryUI @optionalStyleSheet

                        }
                    } elseif ($Collection.Partition) {
                    
                        $name = ""
                        $realThing = Get-AzureTable -TableName $pipeworksManifest.Table.Name -Partition $Collection.Partition -Row  ($items).RowKey 
                        $thingHtml = $realThing | 
                            Out-HTML -ItemType $realThing.pstypenames[-1]
                        & $showThing @colorScheme -Name $thingTitle -Thing $thingHtml |
                            New-WebPage -Title $thingTitle -UseJQueryUI @optionalStyleSheet
                        
                        # Get the row
                    }
                }
            }
            
            $handleLayers = {
                
                $items += $_
                $layername = 
                    if ($_.Name) {
                        if ($_.Extension) {
                            # Pick out everything up to the first .
                            $_.Name.Substring(0, $_.Name.IndexOf(".") - 1)
                        } else {
                            $_.Name
                        }
                    } else {
                        " " + ($order.Count + 1)
                    }
                
                if ($Collection.Partition -and $_.RowKey) {
                    $popoutUrls[$layername] = ("../" * $depth) + "Module.ashx?id=$($Collection.Partition):$($_.RowKey)"
                    $popouts[$layername] = " "                                        
                } elseif ($Collection.Directory) {
                    if ($_ -is [IO.FileInfo]) {
                        if ($_.Extension -eq '.md') {
                            $popouts[$layername] = [IO.File]::ReadAllText($_.fullname) |
                                ConvertFrom-Markdown
                        } elseif ($_.Fullname -like '*demo.ps1' -or 
                            $_.Fullname -like '*walkthru.help.txt' -or
                            $_.fullname -like '*demo.txt') {
                            $popouts[$layername] = Write-WalkthruHTML -WalkThru (Get-Walkthru -File $_.FullName)
                        } elseif ($_.Extension -eq '.ps1') {
                            $popouts[$layername] = & $_.Fullname | Out-HTML 
                        }
                    } else {
                        $itemType = $_.pstypenames[-1]
                        $popouts[$layername]  = $_ | Out-HTML -ItemType $itemType
                    }
                    # Read files that can be read
                }
                $order += $layername
            }             $initLayers = {
                $popouts = @{}
                $popoutUrls = @{}
                $items = @()
                $order = @()
                $depth = 0
                if ($request -and 
                    $request.Params -and 
                    $request.Params["HTTP_X_ORIGINAL_URL"]) {
                
                    $originalUrl = $context.Request.ServerVariables["HTTP_X_ORIGINAL_URL"]

                    $pathInfoUrl = $request.Url.ToString().Substring(0, $request.Url.ToString().LastIndexOf("/"))
                            
                        
                        
                    $pathInfoUrl = $pathInfoUrl.ToLower()
                    $protocol = ($request['Server_Protocol'].Split("/", [StringSplitOptions]"RemoveEmptyEntries"))[0]  # Split out the protocol
                    $serverName= $request['Server_Name']                     # And what it thinks it called the server

                    $fullOriginalUrl = $protocol.ToLower() + "://" + $serverName + $request.Params["HTTP_X_ORIGINAL_URL"]
                    $fullOriginalUrl  = $fullOriginalUrl.ToLower()
                    $pathInfoUrl = $pathInfoUrl.ToLower()
                    $relativeUrl = $fullOriginalUrl.Replace("$pathInfoUrl", "")            
                   
                    if ($relativeUrl -like "*/*") {
                        $depth = @($relativeUrl -split "/" -ne "").Count - 1                    
                        if ($fullOriginalUrl.EndsWith("/")) { 
                            $depth++
                        }                                        
                    } else {
                        $depth  = 0
                    }
                }
                $colorScheme=  @{}
                if ($pipeworksManifest.Gallery.HeaderPrimaryColor) {
                    $colorScheme["FirstColor"] = $pipeworksManifest.Gallery.HeaderPrimaryColor
                }
                
                if ($collection.HeaderPrimaryColor) {
                    $colorScheme["FirstColor"] = $collection.HeaderPrimaryColor
                }
                
                
                
                if ($pipeworksManifest.Gallery.HeaderSecondaryColor) {
                    $colorScheme["SecondColor"] = $pipeworksManifest.Gallery.HeaderSecondaryColor
                }
                
                if ($collection.HeaderSecondaryColor) {
                    $colorScheme["SecondColor"] = $collection.HeaderSecondaryColor
                }
                
                if ($pipeworksManifest.Gallery.MainColor) {
                    $colorScheme["ThirdColor"] = $pipeworksManifest.Gallery.MainColor
                }
                
                if ($pipeworksManifest.Gallery.MainTextColor) {
                    $colorScheme["MainTextColor"] = $pipeworksManifest.Gallery.MainTextColor
                }
                
                if ($pipeworksManifest.Gallery.HeaderTextColor) {
                    $colorScheme["HeaderTextColor"] = $pipeworksManifest.Gallery.HeaderTextColor
                }
                    
            }            $renderObjects = @{                Begin = $initLayers                Process = $handleLayers                End = $renderLayers                } 
            
            
            
            if ($relativeUrl -eq "/" -or -not $relativeUrl) {
                # Display the page
            
            
            }
            
            
            $CollectionName, $itemIdentifier = $relativeUrl.Split("/", [StringSplitOptions]"RemoveEmptyEntries")
            
            if ($CollectionNames -notcontains $CollectionName) {
                if (-not $pipeworksManifest.Gallery.DefaultCollection) {
                    Write-Error "No collection named $($CollectionName).  Try $CollectionNames.   <br/> Relative URL was: $relativeUrl .  <br/> Original URL was: $fullOriginalUrl"
                    return
                } else {
                    # There's a default collection, so the collection name attempted value is really the item identifier
                    $ItemIdentifier = $CollectionName
                    $CollectionName = $pipeworksManifest.Gallery.DefaultCollection
                    
                }
            }
            
            $Collection = $Collections | Where-Object { $_.Name -eq $CollectionName -or $_.Name -contains $CollectionName} 
            $CollectionFriendlyName =
                    if ($Collection.FriendlyName) {
                        $Collection.FriendlyName
                    } else {
                        $CollectionName
                    }
            
            if ($collection.SortBy) {
                $sortSetItems = @{
                    Property = $collection.SortBy
                } 
            } else {
                $sortSetItems = @{
                    Property = $sortSetItems
                    Descending = $true
                }
                
            }
            if (-not $ItemIdentifier) {
            
                 
                    if ($collection.Directory) {
                        # Getting all of the items is reasonable, so do so
                        Get-ChildItem -Path "bin\$($module.Name)\$($Collection.Directory)" -Recurse |
                            ForEach-Object $loadFilesInSet |
                            Sort-Object @sortSetItems  |                            
                            ForEach-Object @renderObjects
                    } elseif ($collection.Partition) {
                        $selectItems = (@($Collection.By) + "RowKey" + "Name") | Select-Object -Unique
                            Search-AzureTable -TableName $pipeworksManifest.Table.Name -Filter "PartitionKey eq '$($Collection.Partition)'" -StorageAccount $storageAccount -StorageKey $storageKey -Select $selectItems |
                            Sort-Object @sortSetItems |
                            ForEach-Object @renderObjects
                    }
            
                <## Render the gallery instead of complain
                & $showThing @colorScheme -Name "$($CollectionFriendlyName) | No Item Identifier" -Thing $thingHtml |
                    New-WebPage -Title "$($CollectionFriendlyName) | No Item Identifier" -UseJQueryUI
                                    
                  #>  
                return
            }            

            $itemIdentifier = foreach ($i in $itemIdentifier) {
                [Web.httpUtility]::UrlDecode($i)
            }

            if ($itemIdentifier.Count) {
                
                
                
                
                
            } else {
                # One one ID
                
                
                             
                
                
                if ($Collection.Partition) {                    
                    $selectItems = (@($Collection.By) + "RowKey" + "Name") | Select-Object -Unique
                    $ItemsInSet = Search-AzureTable -TableName $pipeworksManifest.Table.Name -Filter "PartitionKey eq '$($Collection.Partition)'" -StorageAccount $storageAccount -StorageKey $storageKey -Select $selectItems               
                } elseif ($Collection.Directory) {
                    $ItemsInSet  = Get-ChildItem -Path "bin\$($module.Name)\$($Collection.Directory)" -Recurse |
                        ForEach-Object $loadFilesInSet 
                }
                
                
                # Calculate the depth of the virtual URL compared to the real page. 
                # This gets used to convert links to local resources, such as a custom JQuery theme
                
                $depth =0 
                if ($relativeUrl -like "*/*") {
                    $depth = @($relativeUrl -split "/" -ne "").Count - 1                    
                    if ($fullOriginalUrl.EndsWith("/")) { 
                        $depth++
                    }                    
                    
                } else {
                    $depth  = 0
                }
                
                
                
                
                
                
                foreach ($byTerm in $Collection.By) {
                    $ItemsInSet |
                        Sort-Object @sortSetItems | 
                        Where-Object {
                            $_.$byTerm -ilike "*${itemIdentifier}*"
                        } |
                        ForEach-Object @renderObjects
                        
                }
                   
            }
            
            
            return

        
         }      
        
        # If the gallery is public, then there is a page to add items if the person is logged in
        if ($parameter.IsPublic) {
        
        }
        
               
        @{
            "AnyUrl.pspage" = "<| $anyPage |>"
            
        }                                   
    }        
} 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoC/O/QJ/gDCWzuTiiBlAe81u
# 3FagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFM/va+BCbsRAFtwA
# 2NBRDZC3lZ3OMA0GCSqGSIb3DQEBAQUABIIBAJ9bOlNtjQN94SXYcM7L1SJdH2eu
# BZE/LoCW7ISueP2Ir6YfWAhk2u+bQXM/1cs6lctiVLR88dyVz+bes2dUxnyCJHqJ
# ZV2RkqSFuQHKaA3y/FIbiB5MEQ7I7P6Cp0NkEehxCIpISAQQ3niNpWIdpNrWYlPY
# tdF/kWCaBXrJQbqK3mJ/etSt01qliTIAA8LwzVl4ZrrQNJL+1M2P6KPriY4i4i3I
# 3+1Viebd7TV15RtfHzJ21kVXGEmhxdwny20CveSVRgg6/ZKeAd4cB+xgU/8zt9ri
# Z9yDZjdBNlHNRNOtKI4rrALacYSyJPQE3Hr6GHHpRMzxRQmX3ZenxuLfu+c=
# SIG # End signature block
