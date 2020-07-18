function Move-Focus {
    $Direction = [System.Windows.Input.FocusNavigationDirection]::Next
    $Request = New-Object -TypeName System.Windows.Input.TraversalRequest($Direction)
    $global:XamlWindow.MoveFocus($Request)
}

function Enter-MainWindow {

}

function Exit-MainWindow {
        
    $global:XamlWindow.DialogResult = $false

}
