# arsysDNSUpdater
A basic command line tool to auto update the dns entries in https://www.arsys.es. Not endorsed by them or anything, just an exercise in URLSession, SOAP and simple JSON and XML messages handling

The structure needed is that there's a central entry "domain.com/es/whatever" that holds the public IP address, and the other subdomains "host1.domain.com" get the ip as "domain.com" Usefull to be able to have just one public address for home, and redirect traffic in the internal router for the different machines behind the NAT.


# Usage

execute as
arsysDNSUpdater domain controlPanelAccessKey

where:
 - domain: The domain for the entry to be updated
 - controlPanelAccessKey: The password to access the control panel, not necessarily the same as the access password needed for customer zone. You can change the needed password in Control Panel -> Panel Password. Once changed, activate the API access from Control Panel -> DNS Entries -> API -> Activate access. If already activated when changed password, you'll need to switch off and on again.
 
That's the basic preparation needed. I hope somebody finds it usefull, even if it's only as a basic framework for more complex URLSession usage ^.^

BTW needs swift 3.0 included in XCode Version 8.0 beta (8S128d)
