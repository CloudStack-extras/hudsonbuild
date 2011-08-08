#!/bin/bash -e
# functions

function cleanup() {
	test -f /etc/apt/sources.list.vmops.bak && mv -f /etc/apt/sources.list.vmops.bak /etc/apt/sources.list || true
}

function setuprepo() {
	pathtorepo=`pwd`
	echo "Setting up the temporary repository..." >&2
	cp /etc/apt/sources.list /etc/apt/sources.list.vmops.bak
	echo "
deb file://$pathtorepo ./" >> /etc/apt/sources.list

	echo "Fetching updated listings..." >&2
	aptitude update
}

function installed() {
	dpkg -l "$@" 2> /dev/null | grep '^i' > /dev/null || return $?
}

function doinstall() {
	aptitude -o Aptitude::Cmdline::ignore-trust-violations=true -y install "$@" || return $?
}
	
function doupdate() {
	service cloud-agent stop
	newVersion=`dpkg-deb -I ./oss/cloud-agent_*.deb |grep Version|awk '{print $2}'`
        newMajor=`echo $newVersion | cut -d \. -f 3`
        newMinor=`echo  $newVersion |cut -d \. -f 4|cut -d \- -f 1`
        version=`dpkg -s cloud-agent |grep Version|awk '{print $2}'`
        major=`echo $version |cut -d \. -f 3`
        minor=`echo $version |cut -d \. -f 4|cut -d \- -f 1`
        if [ "$newMajor" == "8" ]
        then
           if [ "$major" -lt "8" ]
           then
		ebtables -t nat -F
                apt-get remove "cloud*" -y
                doinstall cloud-agent cloud-agent-premium
	        service cloud-agent restart
                return
           fi
           if [ "$major" == "8" -a "$minor" -lt "6" ]
           then
               apt-get remove "cloud*" -y
	       ebtables -t nat -F
               doinstall cloud-agent cloud-agent-premium
	       service cloud-agent restart
               return
           fi
        fi

	apt-get --force-yes -y upgrade "cloud*"
	service cloud-agent restart
}
	
function doremove() {
        service cloud-agent stop
	apt-get -y purge "$@" || return $?
        for rsscript in `find /etc/rc*.d -name "*cloud-agent"`
        do
           rm $rsscript
        done
}

trap "cleanup" INT TERM EXIT

cd `dirname "$0"`
setuprepo

installag="    A) Install the Agent
"
quitoptio="    Q) Quit
"
unset removedb
unset upgrade
unset remove

if installed cloud-agent ; then
	upgrade="    U) Upgrade the myCloud packages installed on this computer
"
	remove="    R) Stop any running myCloud services and remove the myCloud packages from this computer
"
fi
if installed cloud-agent ; then
	unset installag
fi

aflag=
while getopts 'yh' OPTION
do
  case $OPTION in
  y)    aflag=1
        ;;
  esac
done

if [ "$aflag" == "1" ]
then
   installtype="A"
   if installed cloud-agent; then
        installtype="U"
   fi
else

   read -p "Welcome to the Cloud.com myCloud Installer.  What would you like to do?

$installag$upgrade$remove$quitoptio
    > " installtype

fi

if [ "$installtype" == "q" -o "$installtype" == "Q" ] ; then

	true

elif [ "$installtype" == "a" -o "$installtype" == "A" ] ; then

	echo "Installing the Agent..." >&2
	if doinstall cloud-agent cloud-agent-premium ; then
		echo "Agent installation is completed" >&2
		echo "Don't forget to set up the Agent with the mycloud-setup-agent command" >&2
	else
		true
	fi

elif [ "$installtype" == "u" -o "$installtype" == "U" ] ; then

	echo "Updating the myCloud and its dependencies..." >&2
	doupdate

elif [ "$installtype" == "r" -o "$installtype" == "R" ] ; then

	echo "Removing all myCloud packages on this computer..." >&2
	doremove 'cloud*'

else

	echo "Incorrect choice.  Nothing to do." >&2
	exit 8

fi

cleanup

