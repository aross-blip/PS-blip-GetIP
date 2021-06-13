Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
#Your XAML goes here :)
$inputXML = @"
<Window x:Class="WpfApp11111.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp11111"
        mc:Ignorable="d"
        Title="Get-IP-Address" Height="338" Width="561">
    <Grid Margin="10,0,10,8" Background="#FFFDFDFD">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="101*"/>
            <ColumnDefinition Width="432*"/>
            <ColumnDefinition Width="19*"/>
        </Grid.ColumnDefinitions>
        <Label Content="Internal IP" HorizontalAlignment="Left" Margin="68,80,0,0" VerticalAlignment="Top" Height="36" Width="81" FontSize="16" Grid.ColumnSpan="2"/>
        <Label Content="External IP" HorizontalAlignment="Left" Margin="68,121,0,0" VerticalAlignment="Top" Height="36" Width="97" FontSize="16" Grid.ColumnSpan="2"/>
        <TextBox x:Name="InternalText" HorizontalAlignment="Left" Height="36" Margin="92,80,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="211" Background="#FFD8D8D8" Grid.Column="1" FontSize="20"/>
        <TextBox x:Name="ExternalText" HorizontalAlignment="Left" Height="36" Margin="92,121,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="211" Background="#FFD8D8D8" Grid.Column="1" FontSize="20"/>
        <Button Content="Close" HorizontalAlignment="Left" Margin="182,235,0,0" VerticalAlignment="Top" Height="49" Width="211" IsCancel="True" FontSize="20" Grid.Column="1"/>
        <Button x:Name="GetIP" Content="Get IP" HorizontalAlignment="Left" Margin="35,235,0,0" VerticalAlignment="Top" Height="49" Width="211" Grid.ColumnSpan="2" FontSize="16"/>

    </Grid>
</Window>
"@ 
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
try{
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
}
catch{
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}
 
#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
  
$xaml.SelectNodes("//*[@Name]") | %{
    try {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
    }

#The magic starts here
$WPFInternalText.IsReadOnly = $True
$WPFExternalText.IsReadOnly = $True

$WPFGetIP.Add_Click({
    $localInterface = (Get-NetAdapter -physical | where status -eq 'up').InterfaceAlias
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $localInterface).IPAddress
    if ($localInterface.count -gt 1) {
        for ($index = 0; $index -lt $localInterface.count; $index++ ){
            $temp = $($localInterface[$index]), $($localIP[$index])
            $list += $temp+"`n"
        }
        [System.Windows.Forms.MessageBox]::Show("Multiple physical interfaces with status 'up' found: `n$list", "Error", `
        [System.Windows.Forms.MessageBoxButtons]::OK, `
        [System.Windows.Forms.MessageBoxIcon]::Error)
    } elseif ([string]::IsNullOrWhiteSpace($localInterface)) {
        [System.Windows.Forms.MessageBox]::Show("No adapter found", "Error", `
        [System.Windows.Forms.MessageBoxButtons]::OK, `
        [System.Windows.Forms.MessageBoxIcon]::Error)
    } else {
        $WPFInternalText.Text = $localIP
    }
    try {
        $WPFExternalText.Text = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
    } catch {
        
        [System.Windows.Forms.MessageBox]::Show("$Error `nPossible cause: there is no Internet connection available", "Error", `
        [System.Windows.Forms.MessageBoxButtons]::OK, `
        [System.Windows.Forms.MessageBoxIcon]::Error)
        $Error.Clear()
    }
})

$Form.ShowDialog() | out-null