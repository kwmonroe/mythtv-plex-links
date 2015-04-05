#!/bin/bash
# mythpreprocess.sh written by Justin Decker, copyright 2015. For licensing purposes,
# use GPLv2
#
# To use, create a "recording started" event that runs like so:
#  /path/to/script/mythpreprocess.sh "%CHANID%" "%STARTTIMEUTC%"

# The following values adjust the script parameters:
#
# Set this to the directory of the Plex Library where myth recording symlinks
# should reside.
PLEXLIBRARYDIR="/mnt/esata/recordedtv"
# Set this to the URL prefix of your Plex Media Server
PMSURL="http://192.168.1.20:32400/"
# Set this to the section number of your recorded TV shows library. To find
# this out, go to your plex media server and navigate to the desired library.
# Look at the URL for that page, and at the end you should see
# /section/<number>. The number here is your section number.
PMSSEC="6"
# Set this to the location of the mythtv config.xml file. It's needed to
# determine the mysql login. If you're running mythbuntu, you shouldn't need to
# change this.
CONFIGXML="/home/mythtv/.mythtv/config.xml"

# Leave everything below this line alone unless you know what you're doing.
#
# Discover mysql username and password from mythtv config.xml. Alternatively
# you can manually enter them after the = sign.
DBUSER="$(awk -F '[<>]' '/UserName/{print $3}' $CONFIGXML)"
DBPASS="$(awk -F '[<>]' '/Password/{print $3}' $CONFIGXML)"

# TODO: sanity check values
CHANID=$1 && STARTTIME=$2

# Populate recording information from sql database
RECORDING=($(mysql mythconverg --user=$DBUSER --password=$DBPASS -se \
  "SELECT title, season, episode, basename, storagegroup  FROM recorded WHERE chanid=\"$CHANID\" AND starttime=\"$STARTTIME\";"))

# Set vars from above query results, padding season and episode with 0 if needed
# TODO: sanity check values
TITLE=${RECORDING[0]}
SEASON=`printf "%02d" ${RECORDING[1]}`
EPISODE=`printf "%02d" ${RECORDING[2]}`
FILENAME=${RECORDING[3]}
STORAGEGROUP=${RECORDING[4]}

SGDIR=$(mysql mythconverg --user=$DBUSER --password=$DBPASS -se \
  "SELECT dirname FROM storagegroup WHERE groupname=\"$STORAGEGROUP\";")

MYTHFILE="$SGDIR/$FILENAME"
PLEXFILE="$TITLE - s${SEASON}e${EPISODE} - $STARTTIME.mpg"
PLEXSHOWDIR="$PLEXLIBRARYDIR/$TITLE"
PLEXFILEPATH="$PLEXSHOWDIR/$PLEXFILE"

# create pretty name and path for file
mkdir -p "$PLEXSHOWDIR"
ln -s "$MYTHFILE" "$PLEXFILEPATH"

# Prune all dead links and empty folders
find -L "$PLEXLIBRARYDIR" -type l -delete
find "$PLEXLIBRARYDIR" -type d -empty -delete

# Update Plex library
curl "$PMSURL"library/sections/"$PMSSEC"/refresh
