#!/bin/bash
#mesos slave deployment script

MESOSRPM="http://downloads.mesosphere.io/master/centos/6/mesos_0.14.1_x86_64.rpm"
CONFIGPATH="/opt/mesos-deploy/"
SLAVECONFIGFILE="slave.conf"
INITFILE="/etc/init.d/mesosslave"
SERVICENAME="mesosslave"


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

#create mesos config directory
echo "creating configuration directory"
mkdir -p $CONFIGPATH

echo "creating configuration file "
echo "using mesos master:$ZK "
#write config file
echo "ZKHOST="$ZK"" > "$CONFIGPATH$SLAVECONFIGFILE"

echo "creating init scripts"
cat <<END >$INITFILE
#!/bin/bash
# 
# chkconfig: 2345 89 9 
# description: mesosslave

source /etc/rc.d/init.d/functions
source /opt/mesos-deploy/slave.conf

RETVAL=0
lockfile="/var/lock/subsys/mesosslave"
desc="Mesos slave daemon"

if [[ -z \$ZKHOST ]]
then
     echo "Please run mesos_slave_deploy.sh first"
     exit 1
fi



 start() {

       public_hostname="\$( curl -sSf --connect-timeout 1 http://169.254.169.254/latest/meta-data/public-hostname )"
       echo "Setting hostname to \$public_hostname"
       hostname \$public_hostname
       echo \$public_hostname > /etc/hostname
       HOSTNAME=\$public_hostname

       echo -n "Starting Mesos slave daemon"
       echo "Mesos Master host:\$ZKHOST"
       
       /usr/local/sbin/mesos-slave --master=zk://\$ZKHOST:2181/mesos --quiet --log_dir=/var/log/mesos & >/var/log/mesosslave.log
        echo \$! > /var/run/mesosslave.pid
        success \$"mesosslave startup"
        echo
     
}


stop() {
        echo -n "Stopping mesosslave"
        pkill mesos-slave
      
        echo
}
### main logic ###
case "\$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        status mesos-slave
        ;;
  restart|reload|condrestart)
        stop
        start
        ;;
  *)
        echo \$"Usage: \$0 {start|stop|restart|reload|status}"
        exit 1
esac
exit 0

END

chmod 755 $INITFILE
echo "setting up monit scripts"

cat <<END >/etc/monit.d/mesosslave.conf
check process mesos_slave with pidfile /var/run/mesosslave.pid

       start = "/etc/init.d/mesosslave start"

       stop = "/etc/init.d/mesosslave stop"
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


