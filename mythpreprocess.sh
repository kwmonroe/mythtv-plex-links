#!/bin/bash
# mythpreprocess.sh written by Justin Decker, copyright 2015. For licensing purposes,
# use GPLv2
#
# To use, create a "recording started" event that runs like so:
#  /path/to/script/mythpreprocess.sh "%CHANID%" "%STARTTIMEUTC%"

# The following values adjust the script parameters:
#
# Set this to where the pretty links should reside, making sure to include the
# trailing /.
PRETTYDIRNAME="/storage/htpc/recordedtv/"
# Set this to the URL prefix of your Plex Media Server
PMSURL="http://192.168.1.200:32400/"
# Set this to the section number of your recorded TV shows library. To find
# this out, go to your plex media server and navigate to the desired library.
# Look at the URL for that page, and at the end you should see
# /section/<number>. The number here is your section number.
PMSSEC="8"
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

CHANID=$1 && STARTTIME=$2

# Populate recording information from sql database
TITLE=$(mysql mythconverg --user=$DBUSER --password=$DBPASS -se \
  "SELECT title FROM recorded WHERE chanid=\"$CHANID\" AND starttime=\"$STARTTIME\";")
SUBTITLE=$(mysql mythconverg --user=$DBUSER --password=$DBPASS -se \
  "SELECT subtitle FROM recorded WHERE chanid=\"$CHANID\" AND starttime=\"$STARTTIME\";")
DATE=$(mysql mythconverg --user=$DBUSER --password=$DBPASS -se \
  "SELECT starttime FROM recorded WHERE chanid=\"$CHANID\" AND starttime=\"$STARTTIME\";")
FILENAME=$(mysql mythconverg --user=$DBUSER --password=$DBPASS -se \
  "SELECT basename FROM recorded WHERE chanid=\"$CHANID\" AND starttime=\"$STARTTIME\";")
STORAGEGROUP=$(mysql mythconverg --user=$DBUSER --password=$DBPASS -se \
  "SELECT storagegroup FROM recorded WHERE chanid=\"$CHANID\" AND starttime=\"$STARTTIME\";")
DIRNAME=$(mysql mythconverg --user=$DBUSER --password=$DBPASS -se \
  "SELECT dirname FROM storagegroup WHERE groupname=\"$STORAGEGROUP\";")
FILEPATH="$DIRNAME$FILENAME"
PRETTYNAME="$TITLE $SUBTITLE $DATE.mpg"
PRETTYSUBDIR="$PRETTYDIRNAME$TITLE/"
PRETTYFILEPATH="$PRETTYSUBDIR$PRETTYNAME"

# create pretty name and path for file
mkdir -p "$PRETTYSUBDIR"
ln -s "$FILEPATH" "$PRETTYFILEPATH"
# Prune all dead links and empty folders
find -L $PRETTYDIRNAME -type l -delete
find $PRETTYDIRNAME -type d -empty -delete

curl "$PMSURL"library/sections/"$PMSSEC"/refresh
