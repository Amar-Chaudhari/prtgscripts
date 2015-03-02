# prtgscripts
custom sensor scripts for prtg
Usage :
1. Upload the script to custom sensor folder
2. Add XML Sensor 
3. User parameters as following - 

VIP_Traffic '%host' 'snmp_community_name' '2c' '/common/www.example.com' 'ver11'

Parameter Explanation - 

1. Sensor Type - VIP_Traffic , Pool_Traffic , Node_Traffic , VIP_Session , Pool_Session , Node_Session
2. '%host' - %host will take hostname of device , if not enter hostname of balancer
3. snmp_community_name - snmp community name specified in the balancer.
4. 2c - snmp version , currently supports ONLY 2c
5. /common/www.example.com - VIP name in the balancer , script will automatically conver it to dotted format
5. ver11 - BIGIP OS version , Currently supports v10 & v11 ( version 10 requires 1.4 added to standard oid)
