Import-Module "$PSScriptRoot\modules\Start-WavSoundboard.psm1"
$WavFolder = (Get-ChildItem -Path "$PSScriptRoot\bin" -Directory | Select -First 1).FullName
Start-WavSoundboard -WavPath $WavFolder
pause