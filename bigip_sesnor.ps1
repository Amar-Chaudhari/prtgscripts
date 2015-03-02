Set-Alias snmpget "C:\Program Files (x86)\net-snmp\bin\snmpget.exe"

$sensor_type = $args[0]
$slb_host = $args[1]
$snmp_community = $args[2]
$snmp_version = $args[3]
$sensor_value = $args[4]
$sensor_version = $args[5]

############################################################

function ConvertToOid{
    param([string]$vip_name)

   $vip_name_char = $vip_name.ToCharArray()
   

   $ascii_values = @()
  
   
    foreach ( $char in $vip_name_char){

        $ascii_values += Get-ascii($char)
       
    }
        
    foreach ( $val in $ascii_values ){

        $vip_oid = $vip_oid + [string]"."  + [string]$val

    }

    $len = $ascii_values.Length

    $vip_name_oid = [string]$len + $vip_oid

    return "$vip_name_oid"
}

############################################################

function Get-ascii{
          param([char]$char)
       <#   if($char -match "[1-9]")
          {
            $val = [int][char]$char
          }else
          {
            $val = [int][char]$char
          }
        #>

          $val = [int]$char

          return $val

}

############################################################

if($sensor_type -eq $null)
{
$Res = @"
<prtg>
<error>1</error>
<Text>No Sensor Type</Text>
</prtg>
"@;
$Res;

}
elseif($slb_host -eq $null){

$Res = @"
<prtg> 
<error>1</error>
<Text>No slb host</Text>
</prtg>
"@;
$Res;

}elseif($snmp_community -eq $null){

$Res = @"
<prtg> 
<error>1</error>
<Text>No snmp community Type</Text>
</prtg>
"@;
$Res;

}elseif($snmp_version -eq $null){

$Res = @"
<prtg> 
<error>1</error>
<Text>No snmp version Type</Text>
</prtg>
"@;
$Res;

}elseif($sensor_value -eq $null){

$Res = @"
<prtg> 
<error>1</error>
<Text>No sensor value</Text>
</prtg>
"@;
$Res;

}else{

        if($sensor_type -match "VIP_Traffic") ## if vip traffic sensor , execute following ##
        {

                    $vip_oid = ConvertToOid($sensor_value)
                
                    $traffic_in = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.10.2.3.1.7.$($vip_oid)"
                    
                    $traffic_out = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.10.2.3.1.9.$($vip_oid)"
               

  
                

$s += @"
<result> 
 <channel>Traffic_in</channel>
 <Unit>BytesBandwidth</Unit>
 <mode>Difference</mode>
 <float>1</float>
 <value>$traffic_in</value>
</result>
<result> 
 <channel>Traffic_Out</channel>
 <Unit>BytesBandwidth</Unit>
 <mode>Difference</mode>
 <float>1</float>
 <value>$traffic_out</value>
 </result>`r`n
"@;
 
            ###VIP traffic if ends##
            }
            elseif($sensor_type -match "VIP_Session") ## if VIP session sensor , execute following
            {

                    $vip_oid = ConvertToOid($sensor_value)

                    $cur_sessions = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.10.2.3.1.12.$($vip_oid)"
                  
                   
$s += @"
<result> 
 <channel>Curr Session</channel>
 <value>$cur_sessions</value>
 <CustomUnit>conn/s</CustomUnit>
 <mode>Absolute</mode>
 <float>0</float>
 </result>`r`n
"@;
            }
            elseif($sensor_type -match "Pool_Traffic")  ## if Pool traffic sensor , execute following ##
            {

                    $pool_oid = ConvertToOid($sensor_value)

                    $traffic_in = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.5.2.3.1.3.$($pool_oid)"

                    $traffic_out = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.5.2.3.1.5.$($pool_oid)"




$s += @"
<result> 
 <channel>Traffic_in</channel>
 <Unit>BytesBandwidth</Unit>
 <mode>Difference</mode>
 <float>1</float>
 <value>$traffic_in</value>
</result>
<result> 
 <channel>Traffic_Out</channel>
 <Unit>BytesBandwidth</Unit>
 <mode>Difference</mode>
 <float>1</float>
 <value>$traffic_out</value>
 </result>`r`n
"@;
 
            ###pool traffic if ends##
            }
            elseif($sensor_type -match "Pool_Session")
            {

                    $pool_oid = ConvertToOid($sensor_value)

                    $cur_sessions = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.5.2.3.1.8.$($pool_oid)"


$s += @"
<result> 
 <channel>Curr Session</channel>
 <value>$cur_sessions</value>
 <CustomUnit>conn/s</CustomUnit>
 <mode>Absolute</mode>
 <float>0</float>
 </result>`r`n
"@;
            }
            elseif($sensor_type -match "Node_Traffic") ## if its Node traffic sensor , execute following ##
            {

               
                
                if($sensor_version -match "ver10") ## version requires 1.4 extra to std oid , 4 = length(ip address)
                {

                    $traffic_in = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.4.2.3.1.4.1.4.$($sensor_value)"

                    $traffic_out = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.4.2.3.1.6.1.4.$($sensor_value)"
                }
                elseif($sensor_version -match "ver11")
                {
                    $node_oid = ConvertToOid($sensor_value)
                    $traffic_in = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.4.2.3.1.4.$($node_oid)"

                    $traffic_out = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.4.2.3.1.6.$($node_oid)"
                }




 $s += @"
<result> 
 <channel>Traffic_in</channel>
 <Unit>BytesBandwidth</Unit>
 <mode>Difference</mode>
 <float>1</float>
 <value>$traffic_in</value>
</result>
<result>
 <channel>Traffic_Out</channel>
 <Unit>BytesBandwidth</Unit>
 <mode>Difference</mode>
 <float>1</float>
 <value>$traffic_out</value>
</result>`r`n
"@;
            }
            elseif($sensor_type -match "Node_Session")
            {

                 if($sensor_version -match "ver10")## version requires 1.4 extra to std oid ,4 = length(ip address)
                {

                    $cur_sessions = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.4.2.3.1.9.1.4.$($sensor_value)"

                }
                elseif($sensor_version -match "ver11")
                {
                  
                    $node_oid = ConvertToOid($sensor_value)

                    $cur_sessions = snmpget -OQv -v $snmp_version -c $snmp_community $slb_host "1.3.6.1.4.1.3375.2.2.4.2.3.1.9.$($node_oid)"

                }

$s += @"
<result>
 <channel>Curr Session</channel>
 <value>$cur_sessions</value>
 <CustomUnit>conn/s</CustomUnit>
 <mode>Absolute</mode>
 <float>0</float>
 </result>`r`n
"@;
            }


$a = Get-Date

$Res = @"
<prtg> 
$s <Text>Ok: $a</Text>
</prtg>
"@;

$Res;

}
