#!/sbin/sh

#
# Ramdisk SMF installation.
# Yuri Voinov (C) 2007,2020
#
# ident "@(#)ramdisk_smf_inst.sh    2.0    03/09/20 YV"
#

#############
# Variables #
#############

PROGRAM_NAME="Ramdisk"
SERVICE_NAME="ramdisk"
SCRIPT_NAME="$SERVICE_NAME"
SMF_XML="$SERVICE_NAME"".xml"
SMF_DIR="/var/svc/manifest/system"
SVC_MTD="/lib/svc/method"
CFG_DIR="/etc"
CFG_FILE="ram.conf"

# OS utilities 
CHOWN=`which chown`
CHMOD=`which chmod`
COPY=`which cp`
CUT=`which cut`
ECHO=`which echo`
ID=`which id`
MKDIR=`which mkdir`
SVCCFG=`which svccfg`
SVCS=`which svcs`
UNAME=`which uname`
ZONENAME=`which zonename`

OS_VER=`$UNAME -r|$CUT -f2 -d"."`
OS_NAME=`$UNAME -s|$CUT -f1 -d" "`
OS_FULL=`$UNAME -sr`
ZONE=`$ZONENAME`

###############
# Subroutines #
###############

# Non-global zones notification
non_global_zones ()
{
if [ "$ZONE" != "global" ]; then
 $ECHO "=============================================================="
 $ECHO "This is NON GLOBAL zone $ZONE. To complete installation please copy"
 $ECHO "script $SCRIPT_NAME" 
 $ECHO "to $SVC_MTD"
 $ECHO "in GLOBAL zone manually BEFORE starting service by SMF."
 $ECHO "Note: Permissions on $SCRIPT_NAME must be set to root:sys."
 $ECHO "============================================================="
fi
}

##############
# Main block #
##############

# OS version check
if [ "$OS_NAME" != "SunOS" ]; then
 $ECHO "ERROR: Unsupported OS $OS_NAME. Exiting..."
 exit 1
elif [ "$OS_VER" -lt "10" ]; then
 $ECHO "ERROR: Unsupported $OS_NAME version $OS_VER. Exiting..."
 exit 1
fi

# Superuser check
if [ ! `$ID | $CUT -f1 -d" "` = "uid=0(root)" ]; then 
 $ECHO "ERROR: you must be super-user to run this script." 
 exit 1
fi

$ECHO "-------------------------------------------"
$ECHO "- $PROGRAM_NAME SMF service will be install now -"
$ECHO "-                                         -"
$ECHO "- Press <Enter> to continue,              -"
$ECHO "- or <Ctrl+C> to cancel                   -"
$ECHO "-------------------------------------------"
read p

# Copy config
$ECHO "Copying $CFG_FILE..."
if [ -f "$CFG_FILE" ]; then
 $COPY $CFG_FILE $CFG_DIR
 $CHOWN root:sys $CFG_DIR/$CFG_FILE
 $CHMOD 640 $CFG_DIR/$CFG_FILE
else
 $ECHO "ERROR: $CFG_FILE file not found. Exiting..."
 exit 1
fi

# Copy SMF files 
$ECHO "Copying $PROGRAM_NAME SMF files..."
if [ -f "$SCRIPT_NAME" -a -f "$SMF_XML" ]; then
 $COPY $SCRIPT_NAME $SVC_MTD
 $CHOWN root:sys $SVC_MTD/$SCRIPT_NAME
 $CHMOD 555 $SVC_MTD/$SCRIPT_NAME
 
 $COPY $SMF_XML $SMF_DIR
 $CHOWN root:sys $SMF_DIR/$SMF_XML

 $SVCCFG validate $SMF_DIR/$SMF_XML>/dev/null 2>&1
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** XML service descriptor validation successful";;
  *) $ECHO "*** XML service descriptor validation has errors";;
 esac
 $SVCCFG import ./$SMF_XML>/dev/null 2>&1
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** XML service descriptor import successful";;
  *) $ECHO "*** XML service descriptor import has errors";;
 esac
else
 $ECHO "ERROR: $PROGRAM_NAME SMF service files not found. Exiting..."
 exit 1
fi

$ECHO "Verify $PROGRAM_NAME SMF installation..."

# View installed service
$SVCS $SERVICE_NAME

# Check for non-global zones installation
non_global_zones

$ECHO "If $PROGRAM_NAME services installed correctly, enable and start it now"

exit 0
#