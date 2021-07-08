# Solaris ramdisk SMF
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://github.com/yvoinov/ramdisk_smf/blob/master/LICENSE)

                      ***************
                      * Version 2.0 *
                      ***************

Ramdisk  service  designed to create RAM disks when starting
Solaris.  This  service is implemented to support any number
of  RAM  disks  in the system (limited only by the amount of
available RAM) with the following types:

a)  RAM-disks  without  any  filesystem  (raw). For use with
hi-speed devices, for example, ZFS ARC or ZFS ZIL.

b)  RAM-disks  with  UFS  file system, automatically mounted
on specified mountpoints.

c)  RAM-disks with ZFS, automatically mounted as ZFS storage
pools.

Moreover,  the  system may contain an arbitrary RAM disks of
various types.

It  also  supports automatic backup of the contents of disks
on  the  hard  disk  during  the shutdown of the service and
automatic loading from it when the service starts.

Service  is  completely  configurable  through  config  file
(ram.conf) which placed in /etc during service installation.

Supports Solaris 10 and above.

Note:  Pages  of  RAM disks are locked in memory and are not
swapped.  Determining  the  acceptable aggregate size of RAM
disks  can  be  quite  a challenge. An excessively large RAM
disk  or  a  large  number  of  them  can  lead to increased
swapping  of  other  pages  of  applications  running on the
system.  In  addition, Solaris usually does not allow you to
set  RAM disks larger than a certain size. It is recommended
to experiment with the ramdiskadm tool before installing the
service  in  order to determine the maximum possible size of
RAM disks for a particular system.

Service configuration
---------------------

The   service  configuration  can  be  done  during  editing
ram.conf  configuration  file,  which  will placed into /etc
directory during service installation.

RAM-disks  parameters  specifies  as separate text rows with
symbol ":" as fields separator.

The parameters described in config file header and below.

```
####################################
# Configurable RAM-disks variables #
####################################

# Ramdisk name. Default - ramdisk1
RAMDISK_NAME="ramdisk1"
^^^^^^^^^^^^^^^^^^^^^^^^ This field specifies RAM-disk name.
It uses only internally and can be specify any.

# Ramdisk size. Default - 256m
# Note: Permitted multiplier is defined by ramdiskadm
#       and can be g|m|k|b
RAMDISK_SIZE="256m"
^^^^^^^^^^^^^^^^^^^    RAM-disk  size. By default is 256 Mb,
the  max  possible value is limited by your OS installation.
(see note above), required size is specified by SA.

Note:   For   RAM-disks   with  ZFS  minimal  RAM-disk  size
is limited by ZFS itself, and by default is 64 Mb.

# Ramdisk filesystem. Default is "none" (no filesystem)
# Note: Permitted values is none, zfs, ufs
RAMDISK_FS="ufs"
^^^^^^^^^^^^^^^^   RAM-disk fs type. If specified none, disk
will be wihout fs and not mounted.

# Ramdisk ZFS pool name. Default is "ramdisk_pool"
RAMDISK_ZPOOL_NAME="ramdisk_pool"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ZFS-pool name for RAM-disk
with ZFS.

# **********************************************************
# *** Performance/storage/redundancy ZFS fs/pool props group
# **********************************************************
^^^^^^^^^^^^^  This parameters group is ZFS-specific and can
be defined for modify ZFS-formatted RAM-disks.

# Ramdisk ZFS fs property 1. Default is "recordsize=16k"
RAMDISK_ZFS_PROPERTY1="recordsize=16K"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  ZFS  recordsize  for
RAM-disk.  Can  be  specified  in  interval  512 bytes-128K,
by default for ZFS (if omitted) is 128K.

# Ramdisk zfs fs property 2. Default is "compression=gzip-9"
RAMDISK_ZFS_PROPERTY2="compression=gzip-9"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  ZFS  compression
parameter. By default for service is gzip-9, default for ZFS
is off.

# Ramdisk zfs fs property 3. Default is "checksum=on"
RAMDISK_ZFS_PROPERTY3="checksum=on"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^       ZFS       checksum
prottection.  By  default for ZFS is on, default for service
is  on.  It  is  not  recommend  to turn off this parameter.
In some cases it can speed up RAM-disks.

# Ramdisk zfs pool property 4. Default is "failmode=continue"
RAMDISK_ZPOOL_PROPERTY4="failmode=continue"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    ZFS-property,
which  is  defines system behaviour when impossible to mount
pool. Differences from ZFS defaults, selected for keep start
system in multi-user when abnormal system termination occurs
with started ramsidk service with ZFS-formatted disks.

Note:  If  you omit this properties group for RAM-disks with
ZFS, they will set by ZFS defaults.
# **********************************************************
# *** Performance/storage/redundancy ZFS fs/pool props group
# **********************************************************

# Ramdisk mount point. Default /ramdisk1
# Note: Uses if RAMDISK_FS specified. If mountpoint not
#       exists, script create it.
#       If mountpoint is empty, ramdisk will be not mounted.
RAMDISK_MOUNT="/ramdisk1"
^^^^^^^^^^^^^^^^^^^^^^^^^ Name and path RAM-disk mountpoint.
Uses  when  RAM-disks  created with filesystem, both for UFS
and ZFS.

# Ramdisk load/backup directory (mount point).
# Default is "/export/home/ramdisk_backup"
# Note: Set this variable to zero for disable
#       autoload/autobackup
RAMDISK_BACKUP_DIR="/export/home/ramdisk_backup"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  Autobackup
directory.   If  not  specified,  autobackup  function  will
be switch off.

# Ramdisk backup overwrite. Default is "1" (enable).
# Possible values is "1" (enable) or "0" (disable).
# Note: When enable, backup directory contents will
#       complete replaces with RAM-disk content during
#       autobackup. Otherwise it will appends to
#       backup directory contents and possible can case
#       RAM-disk overflow during service startup.
RAMDISK_BACKUP_OVERWRITE="1"    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Autobackup overwrite flag. By default is "1" (on). If set to
"0" (off), autobackup will append autobackup disk directory.
Beware,  in  this mode can be RAM-disk overflow when ramdisk
service  starts.  When set to "1", autobackup directory will
complete replaced with RAM-disk contents during service shut
down.

# Ramdisk operations log. Default is /var/log/ramdisk.log
RAMDISK_LOG="/var/log/ramdisk.log"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  Directory  and  file for
RAM-disk operations logging. It is recommend to include logs
to log rotation scheme.
```

Configuration examples in /etc/ram.conf
---------------------------------------

```
ramdisk1:64m:zfs:ramdisk_pool1:recordsize=16K:compression=gzip-9:checksum=on:failmode=continue:/ramdisk1:/export/home/ramdisk1_backup:1:/var/log/ramdisk1_zfs.log
ramdisk2:64m:zfs:ramdisk_pool2:recordsize=16K:compression=gzip-9:checksum=on:failmode=continue:/ramdisk2:/export/home/ramdisk2_backup:1:/var/log/ramdisk2_zfs.log
ramdisk3:2m:ufs::::::/ramdisk3:/export/home/ramdisk3_backup:1:/var/log/ramdisk3_ufs.log
ramdisk4:2m:ufs::::::/ramdisk4:/export/home/ramdisk4_backup:1:/var/log/ramdisk4_ufs.log
ramdisk5:2m:ufs::::::/ramdisk5:/export/home/ramdisk5_backup:1:/var/log/ramdisk5_ufs.log
```

Service installation
--------------------
To    install    service    login    as    root    and   run
ramdisk_smf_inst.sh.  After complete, you can enable it with
svcadm enable ramdisk command.

Service FMRI is svc:/system/ramdisk:default .

Service uninstallation
----------------------

It  is  strongly recommended to stop and disable serive with
svcadm    disable    ramdisk    command    before    service
uninstallation.  After  that,  you  can completely uninstall
ramdisk  service  with  ramdisk_smf_rmv.sh  script.  If  you
remove  service  without disabling them, sidebar effects can
occur  -  ramdisk  data  loss,  remain  ramdisk  ZFS  pools,
mountpoints, etc.

When  you uninstall service, config file, RAM-disks logs and
backup directories will also be removed.

Attention!  Huge  RAM-disks  creation  and  formatting  (and
autobackup  and restore) can consume much time, then timeout
specified  in  service  manifest  ramdisk.xml.  By  default,
service  timeout  specified  to  900  seconds  (15 minutes).
If   service  can't  complete  for  this  time,  it  transit
to  maintenance  state.  In  this  case, increase start/stop
timeouts  in  ramdisk.xml  file  and reload service manifest
by svccfg import command.
