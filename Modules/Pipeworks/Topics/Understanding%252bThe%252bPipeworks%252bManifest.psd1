@{
    Name = 'Understanding the Pipeworks Manifest'
    PSTypeName = 'http://shouldbeonschema.org/Topic'
    Content =  ConvertFrom-Markdown @"
The Pipeworks Manifest is a PowerShell data file (.psd1) that describes settings for a module.  These settings are used directly by Pipeworks, or are used by a Pipeworks Schematic.  Each Pipeworks Manifest is located in the module directory and is named _ModuleName_.pipeworks.psd1.




### Common Pipeworks Manifest Sections: 
* [The WebCommand Section of the Pipeworks Manifest](/Topic/The WebCommand Section of the Pipeworks Manifest)
"@
                

}