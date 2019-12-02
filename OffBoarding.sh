#!/bin/bash

# Tomos Tyler 2019 - D8 Services
# Version 1.1
# History 
#	1.0 Initial Creation
#	1.1 Altered with Comments and Salted Credentials Variables
#
# Script overview
# Developed to help clients clense their computers post enrollment. This
# can be useful when testing of decomissioning of computers.
# 
# Instructions
# The following script will NOT check to see if you have variables set. 
# This is because the script asks you which components to remove, if you leave 
# a variable blank the process will error. We assume you will leave variables
# blank that you do not wish to use. Ensure that the items to remove list
# is accurate.
#
# The removal of a computer from the Jamf PRO server will leverage 
# Encrypted Script Parameters 
# See https://github.com/jamf/Encrypted-Script-Parameters for more information
# 
###############################################################
#	Copyright (c) 2019, D8 Services Ltd.  All rights reserved.  
#											
#	
#	THIS SOFTWARE IS PROVIDED BY D8 SERVICES LTD. "AS IS" AND ANY
#	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#	DISCLAIMED. IN NO EVENT SHALL D8 SERVICES LTD. BE LIABLE FOR ANY
#	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
###############################################################
#

#Only Run as Root
thisUser=`whoami`
if [[ $thisUser != "root" ]];then
	echo "Can only run as root"
	exit 1
fi

# Items to remove
removeNomad="true"
removeManagementFolder="true"
removeJamfBinary="true"
removeSelfHeal="true"
removeNoMADRefresh="true"
removeComputerJamf="true"
removePolicyBanner="true"
removeLoginWindowText="true"

##### custom Paths #####
# If D8 Services Self heal is installed, specify the LaunchD Name
selfHealLaunchD="/Library/LaunchDaemons/com.d8services.selfheal.plist"
# Self Heal Script name to be removed and full path
SelfHealScript="/Library/Management/Scripts/SelfHeal.sh"
# If NoMAD Refresh is present, we will need the plist name
nomadRefreshLaunchD="/Library/LaunchAgents/com.d8services.NoMADRefresh.plist"
# Generic Folder where data which is used by your company
managementFolder="/Library/Management/"
# API Salted Credentials, ensure the user is limited to reading and deleteing computers
# Custom per site or server. 
# See https://github.com/jamf/Encrypted-Script-Parameters for more information
apiuserSalt="d278225b2cf07d19"
apiuserPhrase="30aa6c4b854a14f00414c644"
apipassSalt="bf7939b07dde0603"
apipassPhrase="affa996ddcd29a39d366852b"
apiUserPP="${4}"
apiPassPP="${5}"

##### App paths #####
jamfBinaryCLI="/usr/local/jamf"
jamfSymLink="/usr/local/bin/jamf"
NoMADApp="/Applications/NoMAD.app"
NoMADLaunchAgent="/Library/LaunchAgents/com.trusourcelabs.NoMAD.plist"

# Extract selfHeal LaunchD name
shfilename=$(basename -- "$selfHealLaunchD")
shextension="${filename##*.}"
shfilename="${filename%.*}"

# Get Mac Serial
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
jssURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)

###### Functions ##########
# Check if SelfHealLaunchD loaded, unload and then remove
f_removeSelfHeal(){
	if [[ -f ${selfHealLaunchD} ]];then
		launchctl list | grep $shfilename
		if [[ $? == "0" ]];then
			launchctl unload ${selfHealLaunchD}
		fi
		rm ${selfHealLaunchD}
	fi

	if [[ -f ${SelfHealScript} ]];then
			rm ${SelfHealScript}
	fi
}

f_removeNoMADRefresh(){
	if [[ -f ${nomadRefreshLaunchD} ]];then
			rm ${nomadRefreshLaunchD}
	fi
}

f_removeNomad(){
	if [[ -d ${NoMADApp} ]];then
			rm -Rf ${NoMADApp}
	fi
	if [[ -f ${NoMADLaunchAgent} ]];then
			rm -R ${NoMADLaunchAgent}
	fi
}

f_removeManagementFolder(){
	if [[ -d ${managementFolder} ]];then
			rm -Rf ${managementFolder}
	fi
}

f_removeJamfBinary(){
	jamf removeFramework
}

f_removePolicyBanner(){
 if [ -e /Library/Security/PolicyBanner.txt ] || [ -e /Library/Security/PolicyBanner.rtf ] || [ -e /Library/Security/PolicyBanner.rtfd ]; then
	#File Exists
 rm -rf /Library/Security/PolicyBanner.*
fi
}

f_removeFromJamf(){
	if [[ -z ${apiUser} ]]||[[ -z ${apiPass} ]]||[[ -z ${jssURL} ]]||[[ -z ${serialNumber} ]]||[[ -z ${apiuserSalt} ]]||[[ -z ${apiuserPhrase} ]]||[[ -z ${apipassSalt} ]]||[[ -z ${apipassPhrase} ]];then
		echo "One or more parameters for leveraging the API are missing, exiting."
		exit 1
	fi
	macID=$(curl -sku $apiUser:$apiPass -H "accept: text/xml" ${jssURL}/JSSResource/computers/serialnumber/${serialNumber} | xmllint --xpath '/computer/general/id/text()' -)
	echo "Jamf ID is $macID"
	if [[ ${macID} -gt "0" ]];then
	echo "Removing Computer from Jamf Server"
 	curl -sku $apiUser:$apiPass -H "accept: text/xml" ${jssURL}/JSSResource/computers/id/${macID} -X DELETE
	fi
}

f_removeLoginWindowText(){
	# Delete the login window text
    defaults delete /Library/Preferences/com.apple.loginwindow.plist LoginwindowText
}

f_assignCredentials(){
	#apiUser
	#Salt: 681f6d404dc0243d | Passphrase: e47624aff99848e8712c511f
	apiUser=$(echo "${apiUserPP}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${apiuserSalt}" -k "${apiuserPhrase}")
	#apiPassword ws5-zY9-s4g-8Gn
	#Salt: 563ec0761abc4380 | Passphrase: 130e4e4b8604d6b4d56dddb6
	apiPass=$(echo "${apiPassPP}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${apipassSalt}" -k "${apipassPhrase}")
}

###### OffBoard Process #####

if [[ ${removeNoMADRefresh} == "true" ]];then
	f_removeNoMADRefresh
fi

if [[ ${removeNomad} == "true" ]];then
	f_removeNomad
fi

if [[ ${removeSelfHeal} == "true" ]];then
	f_removeSelfHeal
fi

if [[ ${removeLoginWindowText} == "true" ]];then
	f_removeLoginWindowText
fi


if [[ ${removeManagementFolder} == "true" ]];then
	f_removeManagementFolder
fi

if [[ ${removeComputerJamf} == "true" ]];then
	f_assignCredentials
	f_removeFromJamf
fi

if [[ ${removePolicyBanner} == "true" ]];then
	f_removePolicyBanner
fi

if [[ ${removeJamfBinary} == "true" ]];then
	f_removeJamfBinary
fi
