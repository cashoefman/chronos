#!/bin/bash
#mesos slave deployment script

MESOSRPM="http://downloads.mesosphere.io/master/centos/6/mesos_0.14.1_x86_64.rpm"
SLAVECONFIGFILE="/etc/mesos/zk"
INITFILE="/etc/init/mesos-slave.conf"
SERVICENAME="mesos-slave"


usage()
{
cat << EOF
usage: $0 options

This script will create mesos slave and register slave on mesos cluster


OPTIONS:
   -h      Show this message
   -z      Zookeeper host
EOF
}

ZK=
while getopts "hz:z:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         z)
             ZK=$OPTARG
             ;;  

         ?)
             usage
             exit
             ;;
     esac
done

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ -z $ZK ]]
then

     usage
     exit 1
fi



if [[ $ZK =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
then
echo "Validating Zookeeper Host address:Done"
else
echo "Please enter Valid Zookeeper Ip address" 1>&2
exit 1
fi




#install dependancies
echo "installing java"
yum -y  install  java-1.7.0-openjdk-devel


echo "Installing Monit"
yum -y install monit
chkconfig monit on
cat <<END >/etc/monit.d/monitserver.conf
 set httpd port 2812 and
     allow 0.0.0.0/0.0.0.0 
      allow admin:ba6zisto read-only
END
service monit start



#install mesos rpm
echo "Downloding and installing mesos packages"
rpm -Uvh $MESOSRPM

if [ $? -eq 0 ]; then


echo "creating configuration file "
echo "using mesos master:$ZK "
#write config file
echo "zk://$ZK:2181/mesos" > "$SLAVECONFIGFILE"

echo "creating init scripts"
cat <<END >$INITFILE
       description "mesos slave"

       start on runlevel [2345]
       respawn

       script
       public_hostname="\$( curl -sSf --connect-timeout 1 http://169.254.169.254/latest/meta-data/local-ipv4 )"
       echo "Setting hostname to \$public_hostname"
       hostname \$public_hostname
       echo \$public_hostname > /etc/hostname
       HOSTNAME=\$public_hostname
       echo \$\$ > /var/run/mesos-slave.pid
       exec /usr/bin/mesos-init-wrapper slave
       end script


       post-stop script
       rm -f /var/run/mesos-slave.pid
       end script

       
END
echo "removing master config files"
rm -rf /etc/init/mesos-master.conf 
echo "setting up monit scripts"

cat <<END >/etc/monit.d/mesosslave.conf
check process mesos_slave with pidfile /var/run/mesos-slave.pid

       start = "/sbin/initctl start mesos-slave"

       stop = "/sbin/initctl stop mesos-slave"


END

monit reload
if [ $? -eq 0 ]; then
  echo "Monit Reloaded  successfully"  
  echo "Mesos slave setup completed successfully"  
  exit 0
else
    echo "Error Reloading monit"
    exit 1
fi



else
    echo "Error installing mesos packages"
    exit 1
fi
