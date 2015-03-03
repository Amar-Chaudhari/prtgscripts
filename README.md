# F5 BIG-IP LTM VIP,Session,Node Sensor Creator

XML Sensor to automatically create sensors for new VIP , Session , Nodes on balancer

## Installation
1. Create XML sensor with :
   sensor name - Auto Add things
   Parameters - '%host' 'ver11' '%deviceid' 'username' 'password' 'Type of Sensors to create'
   Exe/Script - f5_vip_traffic_adv_custom_auto_create_v4.ps1
   Timeout - 900 Sec
2. Create XML Sensor with :
   sensor name - Dummy
   Exe/Script - bigip_sesnor.ps1
   # Keep this sensor paused at all time
    

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Limitations

Sensor Type - VIP_Traffic , Pool_Traffic , Node_Traffic , VIP_Session , Pool_Session , Node_Session
ver11 - BIGIP OS version , Currently supports v10 & v11 ( version 10 requires 1.4 added to standard OID)

## Credits

brianaddicks for the prtgshell

## License

TODO: Write license
