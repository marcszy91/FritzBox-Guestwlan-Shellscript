# FritzBox-Guestwlan-Shellscript
A shellscript for activate and deacitve fritzbox guestwlan and configure it

## Install
	git clone https://github.com/Ezak91/FritzBox-Guestwlan-Shellscript.git
  
	cd FritzBox-Guestwlan-Shellscript

	cd FritzBox-Guestwlan-Shellscript/files

	chmod 755 GuestWlan.sh
  
	chmod 755 cpwmd5

	nano GuestWlan.sh
  
Change PASSWORD to your FritzBox Password and save with CTRL + O
 
## Execute
  Power on:

	./GuestWlan.sh --action="on"
  
  Power off:
  
 	./GuestWlan.sh --action="off"
  
## Configurations

Thera are two ways to configure the wlan settings.
  
  1. Change the default settings in the GuestWlan.sh files
  
  2. Use optional parameter to override default settings like:
  
  
	      ./GuestWlan.sh --action="on" --ssid="GUEST+SSID"
        
For parameters take a look at

        ./GuestWlan.sh --help
