#!/bin/bash -e
function cleanup() {
    rm -f /etc/yum.repos.d/cloud-temp.repo || true
}

function setuprepo() {
    pathtorepo=`pwd`
    echo "Setting up the temporary repository..." >&2
    echo \
"[cloud-temp]
baseurl=file://$pathtorepo
gpgcheck=0
enabled=1
name=CloudStack temporary repository
" > /etc/yum.repos.d/cloud-temp.repo

    echo "Cleaning Yum cache..." >&2
    rm /var/cache/yum/cloud-temp/ -rf
    yum clean expire-cache || true
}

function installed() {
    rpm -q "$@" > /dev/null 2>&1 || return $?
}

function doinstall() {
    yum install "$@" || return $?
}
    
function doupdate() {
    yum update --disablerepo='*' --enablerepo='cloud-temp' || return $?
}
    
function doremove() {
    yum remove "$@" || return $?
}

[ `whoami` != 'root' ] && echo "This script must run as root" && exit 1

trap "cleanup" INT TERM EXIT

cd `dirname "$0"`
setuprepo

installms="    M) Install the Management Server   
"
installag="    A) Install the Agent
"
installbm="    B) Install BareMetal Agent
"
installus="    S) Install the Usage Monitor
"
installdb="    D) Install the database server     
"
quitoptio="    Q) Quit
"
unset removedb
unset upgrade
unset remove

if installed cloud-client || installed cloud-agent || installed cloud-usage || installed cloud-baremetal-agent; then
    upgrade="    U) Upgrade the CloudStack packages installed on this computer
"
    remove="    R) Stop any running CloudStack services and remove the CloudStack packages from this computer
"
fi
if installed cloud-client ; then
    unset installms
fi
if installed cloud-agent ; then
    unset installag
fi
if installed cloud-baremetal-agent ; then
    unset installbm
fi
if installed cloud-usage ; then
    unset installus
fi
if installed mysql-server ; then
    unset installdb
    removedb="    E) Remove the MySQL server (will not remove the MySQL databases)
"
fi

read -p "Welcome to the Cloud.com CloudStack Installer.  What would you like to do?

$installms$installag$installbm$installus$installdb$upgrade$remove$removedb$quitoptio
    > " installtype

if [ "$installtype" == "q" -o "$installtype" == "Q" ] ; then

    true

elif [ "$installtype" == "m" -o "$installtype" == "M" ] ; then

    echo "Installing the Management Server..." >&2
    doinstall cloud-client cloud-premium 
    true

elif [ "$installtype" == "a" -o "$installtype" == "A" ] ; then

    echo "Installing the Agent..." >&2
    if doinstall cloud-agent cloud-premium ; then
        echo "Agent installation is completed, please add the host from management server" >&2
    else
        true
    fi
elif [ "$installtype" == "b" -o "$installtype" == "B" ] ; then
    echo "Installing the BareMetal Agent..." >&2
    doinstall cloud-baremetal-agent
    true

elif [ "$installtype" == "s" -o "$installtype" == "S" ] ; then

    echo "Installing the Usage Server..." >&2
    doinstall cloud-usage cloud-premium 
    true

elif [ "$installtype" == "d" -o "$installtype" == "D" ] ; then

    echo "Installing the MySQL server..." >&2
    if doinstall mysql-server ; then
        /sbin/chkconfig --add mysqld 
        /sbin/chkconfig --level 345 mysqld on
        if /sbin/service mysqld status > /dev/null 2>&1 ; then
            echo "Restarting the MySQL server..." >&2
            /sbin/service mysqld restart # mysqld running already, we restart it
        else
            echo "Starting the MySQL server..." >&2
            /sbin/service mysqld start   # we start mysqld for the first time
        fi
    else
        true
    fi

elif [ "$installtype" == "u" -o "$installtype" == "U" ] ; then

    echo "Updating the CloudStack and its dependencies..." >&2
    doupdate

elif [ "$installtype" == "r" -o "$installtype" == "R" ] ; then

    echo "Removing all CloudStack packages on this computer..." >&2
    doremove 'cloud-*'

elif [ "$installtype" == "e" -o "$installtype" == "E" ] ; then

    echo "Removing the MySQL server on this computer..." >&2
    doremove 'mysql-server'
else

    echo "Incorrect choice.  Nothing to do." >&2
    exit 8

fi


echo "Done" >&2
cleanup