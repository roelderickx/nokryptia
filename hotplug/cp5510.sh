#!/bin/bash
# GPL License v 2.0 -  Made by Luigi Paiella - paiella@bigfoot.com
#
# Last UPDATE
#rev 0.0.5 - 24-01-2003 - Bugfix: nokryptia seems to be able to corrupt fs
# trying with "mv"... (issue: needed a temp space for one file)
# (in case it happens: it's possibile to use in DOS chkdsk E: /F, probably on linux with fsck)
#rev 0.0.4 - 23-01-2003 - Bugfix:
#  - possible to "ear" 3 beeps on connection & 6 beeps on end
#  - added sync option to avoid error in synching filesystem
#rev 0.0.1 - 03-01-2003 - 1st built
#
# TODO check if is necessary (with hotplug) kernel recompile or not !!!!!

#------------- PARAMETERS ----------------
LINK_DIR=/home/luigi/tmp
MNT_DIR=/mnt/nokia5510
#LOG=/dev/tty1
LOG=/home/luigi/tmp/nokryptia.log
#uncomment the following line if you don't need log
#LOG=/dev/null
NOKRYPT=/usr/local/bin/nokryptia
#manual =1 means NO automatic mount / manual=0 means automatic mount (overridable by option)
MANUAL=0
#----UNLESS YOU 'R A PROGRAMMER, DO NOT MODIFY BELOW THIS LINE----------


VERSION="0.0.4"
#----------------

function beep {
#the following is just to beep 3 times once per sec
	#test manual or automatic mode
	GOOF=`date`
	TEMP=`date`
	echo -e "\a $TEMP" > /dev/tty1
	while [ "$TEMP" = "$GOOF" ]
	do
	 TEMP=`date`
	done
	GOOF=`date`
	TEMP=`date`
	echo -e "\a $TEMP" > /dev/tty1
	while [ "$TEMP" = "$GOOF" ]
	do
	 TEMP=`date`
	done
	echo -e "\a $TEMP" > /dev/tty1
}

function ritarda {
GOOF=`date`
	TEMP=`date`
	#echo -e "\a $TEMP" > /dev/tty1
	while [ "$TEMP" = "$GOOF" ]
	do
	 TEMP=`date`
	done
}

echo ""
echo "$0 - ver $VERSION"
echo "-"
echo "Default values:"
echo "Directory containing mp3 links: $LINK_DIR"
echo "Mount Dir for your mobile 5510: $MNT_DIR"
echo "Log file : $LOG"
if [ $MANUAL -eq 0 ] ; then
	echo "Default: AUTOMATIC MODE"
else
	echo "Default: MANUAL"
fi
echo ""

while test $# -gt 0
do
# echo $1
 if [ "$1" = "--man" -o "$1" = "-m" -o "$1" = "--manual" ] ; then
 	MANUAL=1
 fi

if [ "$1" = "-?" -o "$1" = "--help*"  ] ; then
	echo "SCOPE: This program is aimed to EASY transfer you mp3 files to you Nokia 5510"
	echo ""
	echo "REQUIREMENTS:"
	echo " - nokryptia (available at www.mobilix.org) made by roel.derickx@student.ehb.be -"
	echo ""
	echo "SETUP:"
	echo " 1-create a link directory to store LINKS to the mp3 you want to convert"
	echo " 2-tell cp5510.sh, inside this file ,"
	echo "     - where you'll mount your 5510"
	echo "     - where the link dir is"
	echo "     - the name of the log file you want to use"
	echo ""
	echo "HOW TO USE IT:"
	echo " Standard usage:"
	echo " a- COPY (not move!) (preferably as LINKS to avoid -temp- space wasting) your favorite mp3"
	echo "    in the previously defined link dir with your file manager"
	echo "  ***(BE SURE to use the extension mp3 and lower case: .mp3 and not .MP3)***"
	echo " b- connect your Nokia 5510"
	echo " c- execute cp5510: "
	echo "   Your phone will be:"
	echo "        - mounted"
	echo "        - cleaned of JUST the mp3"
	echo "        - fullfilled with the new mp3 (standing in LINK dir $LINK_DIR)"
	echo "   The mp3 in $LINK_DIR will be cleaned"
	echo ""
	echo "AUTOMATIC MODE SETUP in add to previous (if you have hotplug - eg: Linux Mandrake 9.0):"
	echo " 1- Change in this file MANUAL from 1 to 0"
	echo " 2- put cp5510.sh in /etc/hotplug/usb"
	echo " 3- add the following 2 lines at the end of etc/hotplug/usb.usermap"
	echo "      USB Nokia 5510"
	echo "      cp5510               0x0003      0x0421   0x0404     0x0000       0x0000       0x06         0x00            0x00            0x00            0x00               0x00               0x00000000"
	echo ""
	echo "Usage:"
	echo "If everything is setup correctly you need just to create the links and attach your phone to the computer!"
 	echo "Note: you can force manual mode through the arguments -m --man --manual"
	echo ""
	echo ""
	exit
 fi
 shift
done

if [ $MANUAL -eq 0 ] ; then
	echo "AUTOMATIC MODE"
else
	echo "MANUAL"
fi
echo ""

filesyst=1
if [ $MANUAL -eq 0 ] ;  then
#test manual or automatic mode
    filesyst=0
    if mount -w -o sync /dev/sda1 $MNT_DIR ; then 
        filesyst=1
    elif  mount -w -o sync /dev/sda2 $MNT_DIR ; then
        filesyst=1
    fi
fi
if [ $filesyst -eq 1 ] ; then
    beep
    for file in $MNT_DIR/*.lse
    do
        rm -f "$file" 
    done
    date > $LOG
    cd $LINK_DIR
    rename .MP3 .mp3 *.MP3 ; rename .mP3 .mp3 *.mP3 ; rename .Mp3 .mp3 *.Mp3
    # lower case needed by norkyptia
    for file in $LINK_DIR/*.mp3 
    # alternate: $LINK_DIR/*.[m-M][p-P]3
    do 
        cd $LINK_DIR
        if   $NOKRYPT "$file"   ; then
		filetomove=${file%.mp3}.lse
		if mv "$filetomove" "$MNT_DIR" ; then
		   	echo "Ok, file $filetomove moved" >> $LOG
	           	rm -f "$file"
		else
	    		echo "KO Error on moving file $filetomove" >> $LOG
			rm -f "$filetomove"
		fi
	else
	    echo "KO Error on converting file $file" >> $LOG
	fi
    done
else
    echo "cd $MNT_DIR was not possible! Nothing done.-"
fi
echo "Program ended: in automatic mode you'll ear 3 beeps !"

if [ $MANUAL -eq 0 ] ; then
	#test manual or automatic mode
	cd /
	#to allow umount
	sync ; sync ; sync 
	#to flush buffers
	#ritarda ; ritarda ; ritarda
	if umount -f $MNT_DIR ; then
		date >> $LOG
	fi
	beep
	date >> $LOG
fi
# FINE that by the way means "end" in italian!
 