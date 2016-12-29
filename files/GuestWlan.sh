# Autor: Marc Szymkowiak
# Year: 2016
# More on https://github.com/Ezak91/FritzBox-Guestwlan-Shellscript

#Settings
FritzBoxURL="http://fritz.box" #FritzBox Url
Username="" #FritzBox Username (default empty)
Passwd="PASSWORD" #Password for FritzBox Webif

#Wlan default settings
SSID="FRITZ!Box+Guest"  #Name of the guest wlan
SECMODE=3	#secure mode
KEY="FritzGuest" #password of the guest wlan
LANGUAGE="de" #the language
AUTOUPDATE="on" #set autoupdate on/off
GROUPACCESS="on" #set GROUPACCESS on/off
DOWNTIMEACTIV="off" #deactive wlan after given time
DOWNTIME="80" #see DOWNTIMEACTIV time in minutes
WAITFORDISCONNECT="on" #wait for last disconnected user on/off

#const vars
FRITZLOGIN="/login_sid.lua"
DATALUA="/data.lua"
OLDPAGE="%2Fwlan%2Fguest_access.lua"
WEBCLIENT="curl -s"
CPWMD5="tclsh cpwmd5"

#global vars
SID="0000000000000000"
DEBUG=""


LOGIN(){
	htmlLoginPage=$($WEBCLIENT "$FritzBoxURL$FRITZLOGIN")
  SessionInfoChallenge=$(echo "$htmlLoginPage" | sed -n '/.*<Challenge>\([^<]*\)<.*/s//\1/p')
	SessionInfoSID=$(echo "$htmlLoginPage" | sed -n '/.*<SID>\([^<]*\)<.*/s//\1/p')
	Debugmsg=$Debugmsg"LOGIN: Challenge $SessionInfoChallenge \n"
	if [ "$SessionInfoSID" = "0000000000000000" ]; then
		CPSTR="$SessionInfoChallenge-$Passwd"  # Combine Challenge and Passwd
		#Debugmsg=$Debugmsg"LOGIN: CPSTR: $CPSTR -> MD5\n"
		MD5=`$CPWMD5 $CPSTR`  # here the MD5 checksum is calculated
		RESPONSE="$SessionInfoChallenge-$MD5"
		GETDATA="?username=$Username&response=$RESPONSE"
		SID=$($WEBCLIENT "$FritzBoxURL$FRITZLOGIN$GETDATA" | sed -n '/.*<SID>\([^<]*\)<.*/s//\1/p')
	else
		SID=$SessionInfoSID
	fi
	if [ "$SID" = "0000000000000000" ]; then
		DEBUG=$DEBUG"LOGIN: ERROR - Konnte keine gueltige SID ermitteln \n"
  else
    DEBUG=$DEBUG"SID: $SID\n"
	fi
}

#Perform postrequest
PerformPOST(){
	local POSTDATA=$1
	local URL=$FritzBoxURL$2
  DEBUG=$DEBUG"URL : $URL \n"
  DEBUG=$DEBUG"POST : $POSTDATA \n"
	$WEBCLIENT -d "$POSTDATA" "$URL" > "/dev/null"
}

#Activate guestwlan
ActivateGuestWlan(){
	local POSTDATA="xhr=1&sid=$SID&lang=$LANGUAGE&no_sidrenew="
	POSTDATA=$POSTDATA"&autoupdate=$AUTOUPDATE&activate_guest_access=on"
	POSTDATA=$POSTDATA"&guest_ssid=$SSID&sec_mode=3&wpa_key=$KEY"
	POSTDATA=$POSTDATA"&group_access=$GROUPACESS&apply=&oldpage=$OLDPAGE"
	if [ "$DOWNTIMEACTIV" = "on" ]; then
		POSTDADTA=$POSTDATA"down_time_activ=on&down_time_value=$DOWNTIME"
	fi
	if [ "$WAITFORDISCONNECT" = "on" ]; then
		POSTDADTA=$POSTDATA"&disconnect_guest_access=on"
	fi
  PerformPOST $POSTDATA $DATALUA
}

#Deactivate guestwlan
DeactivateGuestWlan(){
	local POSTDATA="xhr=1&sid=$SID&lang=$LANGUAGE&no_sidrenew="
	POSTDATA=$POSTDATA"&autoupdate=$AUTOUPDATE&print=&apply=&oldpage=$OLDPAGE"
	PerformPOST $POSTDATA $DATALUA
}

USAGE()
{
		DEBUG=$DEBUG"./GuestWlan.sh\n"
		DEBUG=$DEBUG"\t-h --help\n"
		DEBUG=$DEBUG"\t--action=on/off needed\n"
		DEBUG=$DEBUG"\t[--ssid='GUEST SSID']\n"
		DEBUG=$DEBUG"\t[--secmode=3]\n"
		DEBUG=$DEBUG"\t[--key='Password']\n"
		DEBUG=$DEBUG"\t[--language='de']\n"
		DEBUG=$DEBUG"\t[--autoupdate=on/off]\n"
		DEBUG=$DEBUG"\t[--groupaccess=on/off]\n"
		DEBUG=$DEBUG"\t[--downtimeactiv=on/off]\n"
		DEBUG=$DEBUG"\t[--downtime=60] downtime in minutes\n"
		DEBUG=$DEBUG"\t[--waitfordisconnect=on/off]\n"
		echo "$DEBUG"
}

#read parameter
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            USAGE
            exit
            ;;
				--action)
						ACTION=$VALUE
						;;
        --ssid)
            SSID=$VALUE
            ;;
        --secmode)
            SECMODE=$VALUE
            ;;
				--key)
		        KEY=$VALUE
		        ;;
				--language)
						LANGUAGE=$VALUE
						;;
				--autoupdate)
				    AUTOUPDATE=$VALUE
				    ;;
				--groupaccess)
						GROUPACCESS=$VALUE
						;;
				--downtimeactiv)
						DOWNTIMEACTIV=$VALUE
						;;
				--downtime)
				    DOWNTIME=$VALUE
				    ;;
				--waitfordisconnect)
						WAITFORDISCONNECT=$VALUE
						;;
        *)
            DEBUG=$DEBUG"ERROR: unknown parameter \"$PARAM\" \n"
            USAGE
            exit 1
            ;;
    esac
    shift
done

if [ "$ACTION" = "" ]; then
	DEBUG=$DEBUG"--action must be on or off \n";
	USAGE
	exit 1
fi

if [ "$ACTION" = "on" ] || [ "$ACTION" = "off" ]; then
	LOGIN
	if [ "$ACTION" = "on" ]; then
		ActivateGuestWlan
	else
		DeactivateGuestWlan
	fi
else
	DEBUG=$DEBUG"--action must be on or off \n";
	USAGE
	exit 1
fi
echo "$DEBUG"
