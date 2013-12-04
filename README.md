#chronos
=======

Mesos, ZooKeeper, Chronos and Monit Deployment &amp; Init Scripts for use on AWS 

### Procedure for Deploying MESOS Cluster on AWS


####Components
* MESOS Master
* MESOS Slave
* ZOOKEEPER 
* CHRONOS
* MONIT

On Cluster Master:  

Components Installed: 
MESOS MASTER / ZOOKEEPER / CHRONOS /MONIT

1. Create Amazon Linux 64 Bit Instance  
2. Create and apply appropriate security group with the following rules  

Port Range | Source Address                       | Description
:-----------|:--------------------------------------|:----------------------------------------------  
0-65535    | security group id Example:sg-223a382 | Allow all traffic inside security group  
22 | 0.0.0.0/0 | SSH  
5050 | 0.0.0.0/0 or specific ip address | Mesos Master  
8080 | 0.0.0.0/0 or specific ip address | Chronos web Ui  
5051 | 0.0.0.0/0 or specific ip address | Mesos slave  
2812 | 0.0.0.0/0 or specific ip address | monit  


3. Download deployment script mesos-master-deploy.sh 
4. run “sudo bash”
5. run “chmod 755 mesos-master-deploy.sh”  
	The command to deploy is:   
              ./mesos-master-deploy.sh -n MESOS_CLUSTER_NAME  


On Cluster Slaves:  

Componenets Installed: MESOS SLAVE/MONIT  

1. Create Amazon Linux 64 Bit Instance  
2. Apply security group above
3. Install appropriate software for jobs to run (eg PHP)
4. Download deployment script mesos-slave-deploy.sh  
 	The command to deploy is:   
         ./ mesos-slave-deploy.sh –z MESOS_MASTER_PRIVATE_IP  
         

