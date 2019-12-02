# OffBoarding
Bash script to off board computers from Jamf

History 
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
