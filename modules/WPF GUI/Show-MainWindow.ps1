param (

    [string[]]$Identity,

    [int]$WindowWidth = 1440,
    [int]$WindowHeight = 820,
    [int]$WindowPadding = 10,
    [int]$ControlLeftMargin = 10,
    [int]$ControlTopMargin = 5,
    [int]$GridRowCount=18,
    [int]$RowHeight = 20,

    [string]$CurrentFolder,
    [string]$Title,
    $Columns
)

if (!$CurrentFolder) {
    $CurrentFolder = $PSScriptRoot
}

# Create a global variable that will be accessible in the functions from MainWindow.psm1 when they are run from within the event handler scriptblocks.
$global:MainWindow = [PSCustomObject]@{

    Log = [bool]$LogDir
    LogDir = $LogDir

}

Import-Module "$CurrentFolder\MainWindow.psm1" -Verbose:$false
Add-Type -AssemblyName PresentationFramework

$XMLRawText = Get-Content "$CurrentFolder\MainWindow.xml"

# Expand PowerShell variables in the XML file, replacing them with parameter values passed to the current script.
[xml]$XML = $ExecutionContext.InvokeCommand.ExpandString($XMLRawText)

# SHENANIGANS TO BUILD THE WINDOW HOW I WANT IT
$ColumnIndex = -1
ForEach ($Column in $Columns) {
    $ColumnIndex++
    $NewColumn = $XML.CreateElement("ColumnDefinition",$XML.Window.xmlns)
    $NewColumn.SetAttribute('Width',"$([math]::round(10/$($Columns.Count)))*")
    $null = $XML.Window.Grid.GetElementsByTagName('Grid.ColumnDefinitions').AppendChild($NewColumn)

    $NewGroupBox = $XML.CreateElement("GroupBox",$XML.Window.xmlns)
    $NewGroupBox.SetAttribute('Grid.Column',$ColumnIndex)
    $NewGroupBox.SetAttribute('Header',$Column.Name)
    $NewGroupBox.SetAttribute('FontWeight','Bold')
    $NewStackPanel = $XML.CreateElement("StackPanel",$XML.Window.xmlns)
    $NewStackPanel.SetAttribute('Orientation','Vertical')
        
    ForEach($File in $Column.Group) {
        $NewButton = $XML.CreateElement("Button",$XML.Window.xmlns)
        $NewButton.SetAttribute('Name',"btn_$($File.Name -replace ' ','')")
        $NewButton.SetAttribute('Content',$($File.Name -replace '_','-'))
        $NewButton.SetAttribute('Height',"$RowHeight")
        $NewButton.SetAttribute('Margin',"$ControlLeftMargin,$ControlTopMargin")
        $NewButton.SetAttribute('Padding',"$ControlLeftMargin,0")
        $NewButton.SetAttribute('Background','Transparent')
        $NewButton.SetAttribute('FontWeight','Bold')
        $null = $NewStackPanel.AppendChild($NewButton)
    }
    
    $NewScrollViewer = $XML.CreateElement("ScrollViewer",$XML.Window.xmlns)


    $null = $NewGroupBox.AppendChild($NewScrollViewer)
    $null = $NewScrollViewer.AppendChild($NewStackPanel)
    $null = $XML.Window.Grid.AppendChild($NewGroupBox)

}

# Load the window
$XmlNodeReader = [System.Xml.XmlNodeReader]::new($XML)
$global:XamlWindow = [Windows.Markup.XamlReader]::Load($XmlNodeReader)

# Create a variable for each named WPF control. Use the Global scope so they will be accessible in the functions from MainWindows.psm1 when they are run from within the event handler scriptblocks.
$XML.SelectNodes("//*[@Name]") | ForEach-Object {
    Set-Variable -Name ($_.Name) -Value $global:XamlWindow.FindName($_.Name) -Scope Global
}

# Create the event handlers for the WPF controls.
$global:XamlWindow.Add_Loaded({Enter-MainWindow})

$global:XamlWindow.add_KeyDown({
    param
    (
      [Parameter(Mandatory)][Object]$sender,
      [Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e
    )
    switch -Regex ($e.Key) {
        '^([A-Z])\Z' {
            $MatchingFile = $Columns.Group | Where-Object -FilterScript {$_.Name -eq $Matches[1]}
            Start-Wav -Wav $MatchingFile.File
        }
        '^([A-Z][0-9])\Z' {
            $MatchingFile = $Columns.Group | Where-Object -FilterScript {$_.Name -eq $Matches[1]}
            Start-Wav -Wav $MatchingFile.File
        }
        '^NumPad([0-9])\Z' {
            $MatchingFile = $Columns.Group | Where-Object -FilterScript {$_.Name -eq $Matches[1]}
            Start-Wav -Wav $MatchingFile.File
        }
        'Escape' {Exit-MainWindow}
    }
})


$Buttons = Get-Variable -Name "btn_*" -Scope Global -ValueOnly | Where-Object -FilterScript {$_ -ne $null}
ForEach ($Button in $Buttons) {
    $MatchingFile = $Columns.Group | Where-Object -FilterScript {"btn_$($_.Name -replace ' ','')" -eq $Button.Name}
    $Scriptblock = [Scriptblock]::Create("Start-Wav -Wav '$($MatchingFile.File)'")
    $Button.add_Click($Scriptblock)
}

# Launch the window asynchronously
$async = $global:XamlWindow.Dispatcher.InvokeAsync({
    $null = $global:XamlWindow.ShowDialog()
    $global:XamlWindow.Activate()
})

# Do stuff in background here

# Wait for the window to complete
$async.Wait() | Out-Null

if ($global:XamlWindow.DialogResult -eq $true) {

    Write-Output $global:MainWindow

}

Remove-Module MainWindow -Force -Verbose:$false