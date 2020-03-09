#!/sbin/sh

#
# Ramdisk SMF remove.
# Yuri Voinov (C) 2007,2020
#
# ident "@(#)ramdisk_smf_rmv.sh    2.0    03/09/20 YV"
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
CUT=`which cut`
ECHO=`which echo`
GREP=`which grep`
ID=`which id`
RM=`which rm`
SVCADM=`which svcadm`
SVCCFG=`which svccfg`
SVCS=`which svcs`
UNAME=`which uname`
WHOAMI=`which whoami`
ZONENAME=`which zonename`

OS_VER=`$UNAME -r|$CUT -f2 -d"."`
OS_NAME=`$UNAME -s|$CUT -f1 -d" "`
OS_FULL=`$UNAME -sr`
ZONE=`$ZONENAME`

################
# Subroutines. #
################

# Non-global zones notification 
non_global_zones_r ()
{
if [ "$ZONE" != "global" ]; then
 $ECHO  "================================================================="
 $ECHO  "This is NON GLOBAL zone $ZONE. To complete uninstallation please remove"
 $ECHO  "script $SCRIPT_NAME" 
 $ECHO  "from $SVC_MTD"
 $ECHO  "in GLOBAL zone manually AFTER uninstalling autostart."
 $ECHO  "================================================================="
fi
}

remove_backups_logs_and_mounts ()
{
 while read v_param
  do
   # If row commented or empty line, skip it
   if [ "`$ECHO $v_param | $CUT -b 1`" = "#" -o -z "`$ECHO $v_param | $CUT -b 1`" ]; then
    continue
   fi
   # Get ramdisk properties from config
   RAMDISK_MOUNT="`$ECHO $v_param | $CUT -f9 -d':'`"
   RAMDISK_BACKUP_DIR="`$ECHO $v_param | $CUT -f10 -d':'`"
   RAMDISK_LOG="`$ECHO $v_param | $CUT -f12 -d':'`"
   # Remove backups
   $RM -Rf $RAMDISK_BACKUP_DIR>/dev/null 2>&1
   # Remove logs
   $RM -Rf $RAMDISK_LOG>/dev/null 2>&1
   # Remove mounts
   $RM -Rf $RAMDISK_MOUNT>/dev/null 2>&1
  done < $CFG_FILE
}

##############
# Main block #
##############

# Pre-remove checks.
# OS version check
if [ "$OS_NAME" != "SunOS" ]; then
 $ECHO "ERROR: Unsupported OS $OS_NAME. Exiting..."
 exit 1
elif [ "$OS_VER" != "10" ]; then
 $ECHO "ERROR: Unsupported $OS_NAME version $OS_VER. Exiting..."
 exit 1
fi

# Superuser check
if [ ! `$ID | $CUT -f1 -d" "` = "uid=0(root)" ]; then 
 $ECHO "ERROR: you must be super-user to run this script." 
 exit 1
fi

$ECHO "------------------------------------------"
$ECHO "- $PROGRAM_NAME SMF service will be remove now -"
$ECHO "-                                        -"
$ECHO "- Note 1:                                -"
$ECHO "- Running $PROGRAM_NAME service will be stopped!-"
$ECHO "-                                        -"
$ECHO "- Note 2:                                -"
$ECHO "- Backup directories, logs and mounts    -"
$ECHO "- also will be removed!                  -"
$ECHO "-                                        -"
$ECHO "- Press <Enter> to continue,             -"
$ECHO "- or <Ctrl+C> to cancel                  -"
$ECHO "------------------------------------------"
read p

# Disabling and stopping SMF service
$ECHO "Disabling and stopping running $PROGRAM_NAME service..."
$SVCADM disable $SERVICE_NAME>/dev/null 2>&1

# Remove SMF files
$ECHO "Remove $PROGRAM_NAME SMF files..."
if [ -f $SVC_MTD/$SCRIPT_NAME -a -f $SMF_DIR/$SMF_XML ]; then
 $SVCCFG delete -f svc:/system/filesystem/$SERVICE_NAME:default>/dev/null 2>&1
 retcode=`$ECHO $?`
 case "$retcode" in
  0) 
   $ECHO "*** $PROGRAM_NAME SMF service uninstallation successfuly"
  ;;
  *)
   $ECHO "*** $PROGRAM_NAME SMF service uninstallation process has errors"
   exit 1 
  ;;
 esac
 $RM -f $SVC_MTD/$SCRIPT_NAME
 $RM $SMF_DIR/$SMF_XML
else
 $ECHO "ERROR: $PROGRAM_NAME SMF service files not found. Exiting..."
 exit 1
fi

# Get backup directories and logs from config file and remove them
$ECHO "Remove backups, logs and mounts..."
remove_backups_logs_and_mounts

# Finally remove config file
$ECHO "Remove $CFG_FILE file..."
$RM -f $CFG_DIR/$CFG_FILE>/dev/null 2>&1

# Check for non-global zones uninstallation
non_global_zones_r

$ECHO "Verify $PROGRAM_NAME SMF uninstallation..."

# Check uninstallation  
$SVCS $SERVICE_NAME>/dev/null 2>&1

exit 0