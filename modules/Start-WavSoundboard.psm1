
function Start-WavSoundboard {
    param (
        $WavPath
    )
    $Title = $WavPath | Split-Path -Leaf
    $ColumnsOfButtons = Get-ChildItem -Path $WavPath -Directory |
        ForEach-Object {
            $CurrentWavFolder = $_.Name
            Get-ChildItem -Path $_.FullName -Filter "*.wav" |
                ForEach-Object {
                    [pscustomobject]@{
                        Folder = $CurrentWavFolder
                        File = $_.FullName
                        Name = $_.Name -replace 'TI_VOC_','' -replace '\.wav',''
                    }
                }
        } |
        Group-Object -Property Folder
    & "$PSScriptRoot\WPF GUI\Show-MainWindow.ps1" -Columns $ColumnsOfButtons -Title $Title
}

$SoundPlayer = [System.Media.SoundPlayer]::new()

function Start-Wav {
    param ($Wav)
    $SoundPlayer.SoundLocation = $Wav
    $SoundPlayer.PlaySync()
}