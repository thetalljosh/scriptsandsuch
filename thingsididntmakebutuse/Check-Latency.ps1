Function Check-Latency
{
    #Parameter Definition
    Param
    (
    [Parameter(position = 1, mandatory = $true)] $Target,
    [Parameter(Position = 0)] $Source,
    [Parameter(Position = 2)] $PacketCount
    )

    #Setting Default Packet Count = 4
    if($PacketCount -eq $null){ $PacketCount = 4 }

    #Conditions to check if credentials are required
    if($Source -ne $null)
    {
        $creds = Get-Credential -Message "Credentials are mandatory to check latency from other Sources"
        $i=1

        $Target | %{
        
        #Tweaking Test-Connection cmdlet to get the desired output               
        $name = $_; Test-Connection -Source $source -ComputerName $_ -Count $PacketCount -Credential $creds| `
        Measure-Object ResponseTime -Maximum -minimum | select @{name='Source Computer';expression={$Source}}, `
        @{name='Target Computer';expression={$name}},  @{name='Packet Count';expression={$_.count}},`
        @{name='Maximum Time(ms)';expression={$_.Maximum}}, @{name='Minimum Time(ms)';expression={$_.Minimum}} 
        
        #Writing the progress of latency calculation
        Write-Progress -Activity 'Sending Packets to Target Computers and collecting Information'`
        -PercentComplete $(($i/$Target.count)*100) -Status "$(($i/$Target.count)*100)% completed"

        $i++
        }|ft * -auto
    }
    elseif($source -eq $null)
    {
        $Source  = hostname
        $i=1
        $Target | %{
        
        #Tweaking Test-Connection cmdlet to get the desired output
        $name = $_; Test-Connection -Source $source -ComputerName $_ -Count $PacketCount| `
        Measure-Object ResponseTime -Maximum -minimum | select @{name='Source Computer';expression={$Source}},`
        @{name='Target Computer';expression={$name}},  @{name='Packet Count';expression={$_.count}},`
        @{name='Maximum Time(ms)';expression={$_.Maximum}}, @{name='Minimum Time(ms)';expression={$_.Minimum}} 
        
        #Writing the Progress of Latency Calculation
        Write-Progress -Activity 'Sending Packets to Target Computers and collecting Information'`
 -PercentComplete $(($i/$Target.count)*100) -Status "$(($i/$Target.count)*100)% completed"

        $i++
        }|ft * -auto
    }
} 
