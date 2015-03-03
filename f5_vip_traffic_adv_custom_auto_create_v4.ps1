Set-Alias snmpwalk "location of snmpwalk"
#Location to snmpwalk.exe
#Download from here - http://www.net-snmp.org/download.html
# Eg : C:\Program Files (x86)\net-snmp\bin\snmpwalk.exe

Import-Module "Location to prtgshell module" -Verbose
#Location to prtgshell module
#Example C:\dev\prtgshell\prtgshell.psm1

$slb_host = $args[0]
$bigip_version = $args[1]
$deviceid = $args[2]
#Todo : Get this as paramter
$prtgServer = "" ## PRTG API Hostname
$username = $args[3]
$password = $args[4]
$custom_run
if($args[5] -match "VIP_Traffic")
{
    $custom_run = "VIP_Traffic"
}elseif($args[5] -match "VIP_Session")
{
   $custom_run = "VIP_Session"
}elseif($args[5] -match "Pool_Traffic")
{
    $custom_run = "Pool_Traffic"
}elseif($args[5] -match "Pool_Session")
{
    $custom_run = "Pool_Session"
}elseif($args[5] -match "Node_Traffic")
{
    $custom_run = "Node_Traffic"
}elseif($args[5] -match "Node_Session")
{
    $custom_run = "Node_Session"
}elseif($args[5] -match "All")
{
    $custom_run = "All"
}
else
{
    $custom_run = "None"
}

$sensor_property = @()
$current_vip_traffic_sensor = @()
$current_vip_session_sensor = @()
$current_pool_traffic_sensor = @()
$current_pool_session_sensor = @()
$current_node_traffic_sensor = @()
$current_node_session_sensor = @()
$renumber_vip_session_sensor = @()
$renumber_vip_traffic_sensor = @()
$renumber_pool_traffic_sensor = @()
$renumber_pool_session_sensor  = @()
$renumber_node_session_sensor = @()
$renumber_node_traffic_sensor = @()
$current_sensor_count = 0
$dummy_sensorid

###################################################################

function Get-ascii{
          param([char]$char)

          <#
          if($char -match "[1-9]")
          {
            $val = [int][char]$char
          }else
          {
            $val = [int][char]$char
          }#>

           $val = [int]$char

          return $val

}

###################################################################
function ConvertToOid{
    param([string]$vip_name)

   $vip_name_char = $vip_name.ToCharArray()
   

   $ascii_values = @()
  
    foreach ( $char in $vip_name_char){

        $ascii_values += Get-ascii($char)
   
    }
        
    foreach ( $val in $ascii_values ){

        $vip_oid = $vip_oid + [string]"." +  + [string]$val

    }

    $len = $ascii_values.Length

    $vip_name_oid = [string]$len + $vip_oid

    return "$vip_name_oid"
}

###################################################################

function getcountervalue{
            param([string]$counter)

            if($counter.Contains("Counter64"))
            {
                $counter_val = $counter.split("=",2)
                $val = $counter_val[1].Split(":",2)
            }
            
            return [int]$val[1]

}

function gethostname{
            Param(
            [Parameter(Mandatory=$True,Position=0)]
            [string]$ip
            )

            $currentEAP = $ErrorActionPreference

            $ErrorActionPreference = "silentycontinue"

            $result = [system.net.dns]::GetHostentry($ip)

            $ErrorActionPreference = $currentEAP

            if ($result)
            {
                return $result.Hostname
            }
            else
            {
                return -1
            }


}

###################################################################

function create_sensor{
            Param(
            [Parameter(Mandatory=$True,Position=0)]
            [string]$sensor_type,
            [Parameter(Mandatory=$True,Position=1)]
            [string]$sensor_name,
            [Parameter(Mandatory=$True,Position=2)]
            [string]$sensor_value,
             [Parameter(Mandatory=$True,Position=3)]
            [string]$sensor_version
            )

     

      $val = Copy-PrtgObject $dummy_sensorid "$($sensor_type): $sensor_name" $deviceid

      $exeperam = "$($sensor_type) '%host' 'mdm' '2c' '$($sensor_value)' '$($sensor_version)'"

      Set-PrtgObjectProperty $val exeparams $exeperam
      Set-PrtgObjectProperty $val mutexname $sensor_type
      Resume-PrtgObject $val

             

}

#####################################################################

function checksensorexists{
             Param(
            [string]$new_sensor_name,
            [string[]]$current_sensor
            )

        foreach ($value in $current_sensor)
        {       
            
                   
            $check = $new_sensor_name.CompareTo($value)
            if($check -eq 0)
            {
                break
            }
            
        }
       
        return $check
        
}      

#####################################################################

function converthextoip{
             Param(
            [string]$hex_nodeName)
           
            $value = $hex_nodeName.Split(' ')

            foreach($char in $value)
            {
                

                if([string]::IsNullOrEmpty($char))
                {
                     #skipemptychar
                }
                else
                {
                    $intvalue = [Convert]::ToInt32($char,16)
                    $node_ip += [string]$intvalue
                    $node_ip += "."
                
                   
                }
            }
            $node_ip = $node_ip.TrimEnd('.')
            $node_ip

}
######################################################################

function rearrange_sensor{
        Param([string[]]$sensor_id)

        foreach ($objid in $sensor_id)
        {

            Move-PrtgObject $objid 1
        }

}

#######################################################################
##### Main Logic Starts here #####



$PrtgConnect = Get-PrtgServer $prtgServer $username 1234 -HttpOnly  # 1234 = passhase (get it from prtg server)


#######################################################################
### Gather All current servers data

$DeviceSensors = Get-PrtgDeviceSensors $deviceid
 foreach ($value in $DeviceSensors)
 {
        
        
                    $sensor = $value.objid
                    
                    $sensor_property = Get-PrtgObjectProperty $sensor exeparams
                    if($sensor_property.Contains("Dummy"))
                    {
                        $dummy_sensorid = $sensor
                    }
                    elseif($sensor_property.Contains("Property not found"))
                    {
                            
                    }else
                    {
                        $sensor_data = $sensor_property.Split("")
                      
                        if($sensor_data[0] -match "VIP_Traffic")
                        {


                                if($sensor_data[4])
                                {
                                        $sensor_data[4] = $sensor_data[4].Replace("'","")
                   
                                        $current_vip_traffic_sensor += $sensor_data[4].Trim()
                                }
                        }
                        elseif($sensor_data[0] -match "VIP_Session")
                        {

                                 if($sensor_data[4])
                                 {
                                        $sensor_data[4] = $sensor_data[4].Replace("'","")
                   
                                        $current_vip_session_sensor += $sensor_data[4].Trim()
                                 }

                        }
                        elseif($sensor_data[0] -match "Pool_Traffic")
                        {
                            if($sensor_data[4])
                            {
                                $sensor_data[4] = $sensor_data[4].Replace("'","")
                   
                                $current_pool_traffic_sensor += $sensor_data[4].Trim()
                            }
                        }
                        elseif($sensor_data[0] -match "Pool_Session")
                        {
                            if($sensor_data[4])
                            {
                                $sensor_data[4] = $sensor_data[4].Replace("'","")
                   
                                $current_pool_session_sensor += $sensor_data[4].Trim()
                            }
                        }
                        elseif($sensor_data[0] -match "Node_Traffic")
                        {

                                if($sensor_data[4])
                                {
                                    $sensor_data[4] = $sensor_data[4].Replace("'","")
                   
                                    $current_node_traffic_sensor += $sensor_data[4].Trim()
                                    
                                }   
                        }
                        elseif($sensor_data[0] -match "Node_Session")
                        {

                                if($sensor_data[4])
                                {
                                    $sensor_data[4] = $sensor_data[4].Replace("'","")
                   
                                    $current_node_session_sensor += $sensor_data[4].Trim()
                                    
                                }   
                        }
                      
                   }

 }


##################################
### Sensor Creation part Starts ##

if($custom_run -match "VIP_Traffic" -or $custom_run -match "All")
{
    $slbdata = snmpwalk -OQ -v 2c -c mdm $slb_host 1.3.6.1.4.1.3375.2.2.10.2.3.1.1

    $i=0
    $vip_traffic_data = New-Object 'object[,]'2000,3
    $num_vip=0

    foreach ( $value in $slbdata )
    {
        $hostname=""
        $hostname = $value.Split("=",2)
        $hostname[1] = $hostname[1].Replace('"',"")
        $vip_traffic_data[$i++,0] = $hostname[1].Trim()
        $num_vip++
    }


    for ($i=0; $i -le $num_vip-1;$i++)
    { 


   
        $balancer_vip = $vip_traffic_data[$i,0]
   
        $check_sensor = checksensorexists $vip_traffic_data[$i,0] $current_vip_traffic_sensor

        if($check_sensor -ne 0)
        {

              $sensor_name = $vip_traffic_data[$i,0]
              $sensor_name = $sensor_name.Replace("/Common/","")
              $sensor_name = $sensor_name.Trim()
          
                  create_sensor "VIP_Traffic" $sensor_name $vip_traffic_data[$i,0] ver11
                  
          
        }
 
    }

}

Start-Sleep -m 1000
###################################################################
#################### VIP Session ##################################

if($custom_run -match "VIP_Session" -or $custom_run -match "All")
{

    $PrtgConnect = Get-PrtgServer $prtgServer $username 4224993752 -HttpOnly


    $slbdata = snmpwalk -OQ -v 2c -c mdm $slb_host 1.3.6.1.4.1.3375.2.2.10.2.3.1.1

    $i=0
    $vip_traffic_data = New-Object 'object[,]'2000,3
    $num_vip=0

    foreach ( $value in $slbdata )
    {
        $hostname=""
        $hostname = $value.Split("=",2)
        $hostname[1] = $hostname[1].Replace('"',"")
        $vip_traffic_data[$i++,0] = $hostname[1].Trim()
        $num_vip++
    }

 

    for ($i=0; $i -le $num_vip-1;$i++)
    { 


   
        $balancer_vip = $vip_traffic_data[$i,0]
   
        $check_sensor = checksensorexists $vip_traffic_data[$i,0] $current_vip_session_sensor

        if($check_sensor -ne 0)
        {

              $sensor_name = $vip_traffic_data[$i,0]
              $sensor_name = $sensor_name.Replace("/Common/","")
              $sensor_name = $sensor_name.Trim()
              create_sensor "VIP_Session" $sensor_name $vip_traffic_data[$i,0] ver11
              
     
        }
 
    }

}

Start-Sleep -m 1000
##################################################################
##################### Pool Traffic and Session addition ##########


if($custom_run -match "Pool_Traffic" -or $custom_run -match "All")
{

$PrtgConnect = Get-PrtgServer $prtgServer $username 4224993752 -HttpOnly


$slbpooldata = snmpwalk -OQ -v 2c -c mdm $slb_host 1.3.6.1.4.1.3375.2.2.5.2.3.1.1

$i=0
$pool_traffic_data = New-Object 'object[,]'2000,3
$num_pool=0

foreach ( $value in $slbpooldata )
{
    $hostname=""
    $hostname = $value.Split("=",2)
    $hostname[1] = $hostname[1].Replace('"',"")
    $pool_traffic_data[$i++,0] = $hostname[1].Trim()
    $num_pool++
}


 

for ($i=0; $i -le $num_pool-1;$i++)
{ 


   
    $balancer_pool = $pool_traffic_data[$i,0]
   
    $check_sensor = checksensorexists $pool_traffic_data[$i,0] $current_pool_traffic_sensor

    if($check_sensor -ne 0)
    {

          $sensor_name = $pool_traffic_data[$i,0]
          $sensor_name = $sensor_name.Replace("/Common/","")
          $sensor_name = $sensor_name.Trim()
          create_sensor "Pool_Traffic" $sensor_name $pool_traffic_data[$i,0] ver11
          
     
    }
 
}

}

Start-Sleep -m 1000

###################################################################
##################### Pool Session ####################################

if($custom_run -match "Pool_Session" -or $custom_run -match "All")
{

$PrtgConnect = Get-PrtgServer $prtgServer $username 4224993752 -HttpOnly


$slbpooldata = snmpwalk -OQ -v 2c -c mdm $slb_host 1.3.6.1.4.1.3375.2.2.5.2.3.1.1

$i=0
$pool_traffic_data = New-Object 'object[,]'2000,3
$num_pool=0

foreach ( $value in $slbpooldata )
{
    $hostname=""
    $hostname = $value.Split("=",2)
    $hostname[1] = $hostname[1].Replace('"',"")
    $pool_traffic_data[$i++,0] = $hostname[1].Trim()
    $num_pool++
}



for ($i=0; $i -le $num_pool-1;$i++)
{ 


   
    $balancer_pool = $pool_traffic_data[$i,0]
   
    $check_sensor = checksensorexists $pool_traffic_data[$i,0] $current_pool_session_sensor

    if($check_sensor -ne 0)
    {

          $sensor_name = $pool_traffic_data[$i,0]
          $sensor_name = $sensor_name.Replace("/Common/","")
          $sensor_name = $sensor_name.Trim()
          create_sensor "Pool_Session" $sensor_name $pool_traffic_data[$i,0] ver11
          
     
    }
 
}

}
###################################################################
##################### Add Node ####################################

Start-Sleep -m 1000

if($custom_run -match "Node_Traffic" -or $custom_run -match "All")
{

    if($bigip_version -match "ver10")
    {
                $nodedata = @()
                $nodedata = snmpwalk -OQxv -v 2c -c mdm $slb_host 1.3.6.1.4.1.3375.2.2.4.3.2.1.2

                $i=0
                $node_traffic_data = New-Object 'object[,]'2000,2
                $num_node=0

    
    
                foreach ( $value in $nodedata )
                {
                      
                    $node_ip = $value.Replace('"',"")
                
                    $node_ip = converthextoip $node_ip
                    $node_traffic_data[$i++,0] = $node_ip
                    $num_node++
       
                }


 

                for ($i=0; $i -le $num_node-1;$i++)
                { 


   
                    $balancer_nodes = $node_traffic_data[$i,0]


                    $check_sensor = checksensorexists $node_traffic_data[$i,0] $current_node_traffic_sensor
    
                    if($check_sensor -ne 0)
                    {
        
                          $sensor_name = $node_traffic_data[$i,0]
                          #$sensor_name = $sensor_name.Replace("/Common/","")
                          #$sensor_name = $sensor_name.Trim()
                          $node_name = gethostname $sensor_name
                         # Write-Host $node_name
                          create_sensor "Node_Traffic" $node_name $node_traffic_data[$i,0] $bigip_version
              
    
     
                    }
 
                }
    }
    elseif($bigip_version -match "ver11")
    {
    
                $nodedata = @()
                $nodedata = snmpwalk -OQ -v 2c -c mdm $slb_host 1.3.6.1.4.1.3375.2.2.4.1.2.1.17

                $i=0
                $node_traffic_data = New-Object 'object[,]'2000,2
                $num_node=0

    
    
              foreach ( $value in $nodedata )
                {
               
                    $hostname=""
                    $hostname = $value.Split("=",2)
                    $hostname[1] = $hostname[1].Replace('"',"")
                    $node_traffic_data[$i++,0] = $hostname[1].Trim()
                    $num_node++
      
      
                }


 

                for ($i=0; $i -le $num_node-1;$i++)
                { 


   
                    $balancer_nodes = $node_traffic_data[$i,0]


                    $check_sensor = checksensorexists $node_traffic_data[$i,0] $current_node_traffic_sensor
    
                    if($check_sensor -ne 0)
                    {
        
                          $sensor_name = $node_traffic_data[$i,0]
                          $sensor_name = $sensor_name.Replace("/Common/","")
                          $sensor_name = $sensor_name.Trim()
                          $node_name = gethostname $sensor_name
                          #Write-Host $node_name
                          create_sensor "Node_Traffic" $node_name $node_traffic_data[$i,0] $bigip_version
              
    
     
                    }
 
                }
        }

}

Start-Sleep -m 1000

if($custom_run -match "Node_Session" -or $custom_run -match "All")
{

    if($bigip_version -match "ver10")
    {
               
                $nodedata = @()
                $nodedata = snmpwalk -OQxv -v 2c -c mdm $slb_host 1.3.6.1.4.1.3375.2.2.4.3.2.1.2

                $i=0
                $node_traffic_data = New-Object 'object[,]'2000,2
                $num_node=0

    
    
                foreach ( $value in $nodedata )
                {
                      
                    $node_ip = $value.Replace('"',"")
                
                    $node_ip = converthextoip $node_ip
                    $node_traffic_data[$i++,0] = $node_ip
                    $num_node++
       
                }


 

                for ($i=0; $i -le $num_node-1;$i++)
                { 


   
                    $balancer_nodes = $node_traffic_data[$i,0]


                    $check_sensor = checksensorexists $node_traffic_data[$i,0] $current_node_session_sensor
    
                    if($check_sensor -ne 0)
                    {
        
                          $sensor_name = $node_traffic_data[$i,0]

                          $node_name = gethostname $sensor_name
                      
                          create_sensor "Node_Session" $node_name $node_traffic_data[$i,0] $bigip_version
              
    
     
                    }
 
                }
    }
    elseif($bigip_version -match "ver11")
    {
                $nodedata = snmpwalk -OQ -v 2c -c mdm $slb_host 1.3.6.1.4.1.3375.2.2.4.1.2.1.17

                $i=0
                $node_traffic_data = New-Object 'object[,]'2000,3
                $num_node=0

                foreach ( $value in $nodedata )
                {
                    $hostname=""
                    $hostname = $value.Split("=",2)
                    $hostname[1] = $hostname[1].Replace('"',"")
                    $node_traffic_data[$i++,0] = $hostname[1].Trim()
                    $num_node++
                }



                for ($i=0; $i -le $num_node-1;$i++)
                { 


   
                    $balancer_nodes = $node_traffic_data[$i,0]


                    $check_sensor = checksensorexists $node_traffic_data[$i,0] $current_node_session_sensor
    
                    if($check_sensor -ne 0)
                    {
        
                          $sensor_name = $node_traffic_data[$i,0]
                          $sensor_name = $sensor_name.Replace("/Common/","")
                          $sensor_name = $sensor_name.Trim()
                          $node_name = gethostname $sensor_name
                          create_sensor "Node_Session" $node_name $node_traffic_data[$i,0] $bigip_version
                          Start-Sleep -m 100
    
     
                    }
 
                }

    }
}

######################################################################################
###################### Renumber Sensors ##############################################

$DeviceSensors = Get-PrtgDeviceSensors $deviceid
 foreach ($value in $DeviceSensors)
 {
        
        
                    $sensor = $value.objid
                    
                 
                    $sensor_name = Get-PrtgObjectProperty $sensor name
                    if($sensor_property.Contains("Property not found"))
                    {
                            
                    }else
                    {
                       
                      
                        if($sensor_name.Contains("Dummy"))
                        {
                            
                                $dummy_objid = $sensor

                        }
                        elseif($sensor_name.Contains("Auto"))
                        {
                                $auto_add_objid = $sensor
                        }
                        elseif($sensor_name.Contains("CPU Load"))
                        {
                               $cpu_load_objid = $sensor
                        }
                        elseif($sensor_name.Contains("VIP_Traffic"))
                        {
                                                       
                                                        
                             $renumber_vip_traffic_sensor += $sensor
                                
                        }
                        elseif($sensor_name.Contains("VIP_Session"))
                        {

                             $renumber_vip_session_sensor += $sensor
                                                              

                        }
                        elseif($sensor_name.Contains("Pool_Traffic"))
                        {
                            
                             $renumber_pool_traffic_sensor += $sensor

                            
                        }
                        elseif($sensor_name.Contains("Pool_Session"))
                        {
                           
                             $renumber_pool_session_sensor += $sensor

                            
                        }
                        elseif($sensor_name.Contains("Node_Traffic"))
                        {

                                
                            $renumber_node_traffic_sensor += $sensor
                                    
                                   
                        }
                        elseif($sensor_name.Contains("Node_Session"))
                        {

       
                            $renumber_node_session_sensor += $sensor
                                    
                                  
                        }
                      
                   }

 }

if($renumber_node_session_sensor){
rearrange_sensor $renumber_node_session_sensor
Start-Sleep -m 100
}
if($renumber_node_traffic_sensor){
rearrange_sensor $renumber_node_traffic_sensor
Start-Sleep -m 100
}
if($renumber_pool_session_sensor){
rearrange_sensor $renumber_pool_session_sensor
Start-Sleep -m 100
}
if($renumber_pool_traffic_sensor){
rearrange_sensor $renumber_pool_traffic_sensor
Start-Sleep -m 100
}
if($renumber_vip_session_sensor){
rearrange_sensor $renumber_vip_session_sensor
Start-Sleep -m 100
}
if($renumber_vip_traffic_sensor){
rearrange_sensor $renumber_vip_traffic_sensor
Start-Sleep -m 100
}
if($cpu_load_objid){ rearrange_sensor $cpu_load_objid }
if($auto_add_objid){ rearrange_sensor $auto_add_objid }
if($dummy_objid){ rearrange_sensor $dummy_objid }


$a = Get-Date

$Res = @"
<prtg>
    <result>
    </result>
   <Text>Ok: $a</Text>
</prtg>
"@;

$Res;