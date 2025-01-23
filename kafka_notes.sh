############ZK start and stop###########
apache-zookeeper-3.8.1-bin/bin/zkServer.sh start
apache-zookeeper-3.8.1-bin/bin/zkServer.sh stop
rm -rf apache-zookeeper-3.8.1-bin/zklogs/*
rm -rf apache-zookeeper-3.8.1-bin/zkdata/version-2


############create admin user for kafka###########
kafka_2.13-3.4.0/bin/kafka-configs.sh --zookeeper hostname1:12182 --zk-tls-config-file /root/certs/zk_tls_config.properties --alter --add-config 'SCRAM-SHA-512=[password='password']' --entity-type users --entity-name admin


############start and stop kafka###########
kafka_2.13-3.4.0/bin/kafka-server-start.sh -daemon kafka_2.13-3.4.0/config/server.properties 
kafka_2.13-3.4.0/bin/kafka-server-stop.sh -daemon kafka_2.13-3.4.0/config/server.properties 


############ZK CLI LOGIN###########
apache-zookeeper-3.8.1-bin/bin/zkCli.sh -server 10.131.42.11:12182 -Djava.security.auth.login.config=/root/apache-zookeeper-3.8.1-bin/conf/jaas.conf


############CREATE KAFKA TOPIC###########
kafka_2.13-3.4.0/bin/kafka-topics.sh --create --topic DL_TEST --partitions 3 --replication-factor 3 --command-config /root/certs/admin.properties --bootstrap-server hostnameprodvmdm:6667,hostnamePRODVPC:6667,hostnameprodvmdmdb:6667


-------------KERNEL & OS
vm.swappiness=1
vm.dirty_background_ratio=10 (5 for appropriate situations)
vm.dirty_ratio=20
When choosing values for these parameters, it is wise to review the number of dirty pages over time while the Kafka cluster is running under load, whether in production or simulated. The current number of dirty pages can be determined by checking the /proc/vmstat file:
# cat /proc/vmstat | egrep "dirty|writeback"
nr_dirty 3875
nr_writeback 29
nr_writeback_temp 0

---------NETWORKING 
net.core.wmem_default and net.core.rmem_default, and a reasonable setting for these parameters is 131072, or 128 KiB.
net.core.wmem_max and net.core.rmem_max, and a reasonable setting is 2097152, or 2 MiB
net.ipv4.tcp_window_scaling to 1
In addition to the socket settings, the send and receive buffer sizes for TCP sockets must be set separately using the net.ipv4.tcp_wmem and net.ipv4.tcp_rmem parameters. These are set using three space-separated integers that specify the minimum, default, and maximum sizes, respectively. The maximum size cannot be larger than the values specified for all sockets using net.core.wmem_max and net.core.rmem_max. An example setting for each of these parameters is “4096 65536 2048000,” which is a 4 KiB minimum, 64 KiB default, and 2 MiB maximum buffer. Based on the actual workload of your Kafka brokers, you may want to increase the maximum sizes to allow for greater buffering of the network connections.
Increasing the value of net.ipv4.tcp_max_syn_backlog above the default of 1024 will allow a greater number of simultaneous connections to be accepted.
Increasing the value of net.core.netdev_max_backlog to greater than the default of 1000 can assist with bursts of network traffic, specifically when using multigigabit network connection speeds, by allowing more packets to be queued for the kernel to process them.
The GC tuning options provided in this section have been found to be appropriate for a server with 64 GB of memory, running Kafka in a 5GB heap. For MaxGCPauseMillis, this broker can be configured with a value of 20 ms. The value for InitiatingHeapOccupancyPercent is set to 35, which causes garbage collection to run slightly earlier than with the default value.



https://medium.com/@ankuabcna/things-nobody-will-tell-you-setting-up-a-kafka-cluster-3a7a7fd1c92d


-----

unset JMX_PORT
unset JMX_PROMETHEUS_PORT
unset KAFKA_JMX_OPTS

----user creation for admin
kafka_2.13-3.4.0/bin/kafka-configs.sh --zookeeper hostnameabcdlkdckr1.hostname:2181 --alter --add-config 'SCRAM-SHA-512=[password='password']' --entity-type users --entity-name admin


-----producing rights
kafka_2.13-3.4.0/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=hostnameabcdlkkfk1.hostname:2181  --add --allow-principal User:dlkdeveloper --producer --topic abc_DL_TEST --resource-pattern-type prefixed

----consuming rights
/home/kafka/kafka_2.13-3.4.0/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=hostnameabcdlkkfk1.hostname:2181  --add --allow-principal User:$1  --consumer --group $1  --topic $2 --resource-pattern-type prefixed

----list the acls
/home/kafka/kafka_2.13-3.4.0/bin/kafka-acls.sh --list --authorizer-properties zookeeper.connect=hostnameabcdlkkfk1.hostname:2181

----list the topics
/home/kafka/kafka_2.13-3.4.0/bin/kafka-topics.sh --list --command-config /data1/kafkacerts/admin.properties --bootstrap-server hostnameabcdlkkfk1.hostname:6667 

----delete the topics
/home/kafka/kafka_2.13-3.4.0/bin/kafka-topics.sh --delete --topic abc_DL_TEST --bootstrap-server hostnameabcdlkkfk1.hostname:6667 --command-config /data1/kafkacerts/admin.properties


-------------create_user.sh
#!/bin/bash
unset JMX_PORT
unset JMX_PROMETHEUS_PORT
unset KAFKA_JMX_OPTS
log_file="modified_users.log"
# Ensure the log file exists
touch "$log_file"
# Check if user has already been modified
if grep -q "^$1," "$log_file"; then
  echo "User $1 has already been modified, skipping..."
else
  echo "Modifying configuration for user: $1"
  # Run Kafka config command to alter user configuration
  /home/kafka/kafka_2.13-3.4.0/bin/kafka-configs.sh --zookeeper hostname5:2181 --alter --add-config "SCRAM-SHA-512=[password='$2']" --entity-type users --entity-name "$1"
  # Append the modified user to log file
  echo "$1,$2" >> "$log_file"
fi



--------------create_topic.sh
#!/bin/bash
unset JMX_PORT
unset JMX_PROMETHEUS_PORT
unset KAFKA_JMX_OPTS

input="topics.txt"
log_file="created_topics.log"

# Ensure the log file exists
touch "$log_file"

while IFS=, read -r line part1 repl
do
  # Check if the topic already exists in the log file
  if grep -q "^$line," "$log_file"; then
    echo "Topic $line already created, skipping..."
  else
    echo "Creating topic: $line with partitions: $part1 and replication factor: $repl"
    
    # Run Kafka topic creation command
    /home/kafka/kafka_2.13-3.4.0/bin/kafka-topics.sh --create --topic "$line" --partitions "$part1" --replication-factor "$repl" \
    --command-config /data/kafka_certs/admin.properties --bootstrap-server hostnameabckfk05.hostname:6667,hostnameabckfk06.hostname:6667,hostnameabckfk07.hostname:6667,hostnameabckfk08.hostname:6667,hostnameabckfk09.hostname:6667
    
    # Append created topic details to the log file
    echo "$line,$part1,$repl" >> "$log_file"
  fi
done < "$input"


--------------kafka.env
export KAFKA_HOME=/home/kafka/kafka_2.13-3.4.0/
export KAFKA_OPTS="-Djava.security.auth.login.config=/home/kafka/kafka_2.13-3.4.0/config/kafka_jaas.conf"
export KAFKA_HEAP_OPTS="-Xmx8G -Xms8G"
export JMX_PORT=9999
export JMX_PROMETHEUS_PORT=9991
export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -javaagent:/data/kafka_certs/jmx_prometheus_javaagent-0.20.0.jar=$JMX_PROMETHEUS_PORT:/data/kafka_certs/kafka_broker.yml"

---------------kafkajass.conf
KafkaServer {
org.apache.kafka.common.security.scram.ScramLoginModule required
username="admin"
password="n1e6my1z";
};
KafkaClient {
org.apache.kafka.common.security.scram.ScramLoginModule required
username="admin"
password="n1e6my1z";
};


------admin.properties
ssl.enabled.protocols=TLSv1.2,TLSv1.1,TLSv1
ssl.truststore.location = /data/kafka_certs/truststore.jks
ssl.truststore.password = 7ecETGlHjzs
ssl.protocol=TLS
security.protocol=SASL_SSL
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="admin" password="n1e6my1z";
group.id=spark- 





---------kafka_notes--------


Final Kafka Notes
 
 
unset JMX_PORT
unset JMX_PROMETHEUS_PORT
unset KAFKA_JMX_OPTS
 
-------------------------------------------------------------
 
To check leader and follower zookeeper
 
echo cons | nc <ip> <port> | grep Mode
echo cons | nc 10.129.36.94 2181 | grep Mode
echo cons | nc 10.129.36.95 2181 | grep Mode
 
-------------------------------------------------------------
 
Command to start Kafka server
 
 
bin/kafka-server-start.sh -daemon  config/server.properties
 
-------------------------------------------------------------
 
Command to start Zookeeper Server
 
 
/home/zookeeper/apache-zookeeper-3.7.1-bin/bin/zkServer.sh start
 
 
-------------------------------------------------------------
 
Command to start zookeeper client
 
 
/home/zookeeper/apache-zookeeper-3.7.1-bin/bin/zkCli.sh -server 10.129.36.93:2181
 
 
-------------------------------------------------------------
 
Command to create topic
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-topics.sh --create --topic macbook --partitions 3 --replication-factor 2 --command-config /data/kafka_certs/admin.properties --bootstrap-server hostnamePRDabcKFK01.hostname:6667,hostnamePRDabcKFK02.hostname:6667,hostnamePRDabcKFK03.hostname:6667,hostnamePRDabcKFK04.hostname:6667,hostnamePRDabcKFK05.hostname:6667,hostnamePRDabcKFK06.hostname:6667,hostnamePRDabcKFK07.hostname:6667
 
-------------------------------------------------------------
 
Command to make describe topic
 
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-topics.sh --describe --command-config /data/kafka_certs/admin.properties --bootstrap-server hostnameprdabckfk01.hostname:6667  --topic ADDVERB_OPENORDER_01
 
 
-------------------------------------------------------------
 
Command to make user
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-configs.sh --zookeeper 10.129.36.95:2181 --alter --add-config 'SCRAM-SHA-512=[password='Pcd34Uu2CGR29nh']' --entity-type users --entity-name ext_addverbwcs_team
 
 
-------------------------------------------------------------
 
List all user
 
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-acls.sh --list --authorizer-properties zookeeper.connect=10.129.36.95:2181
 
-------------------------------------------------------------
 
Command to give consuming rights
 

/home/kafka/kafka_2.13-3.4.0/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=10.129.36.95:2181  --add --allow-principal User:flink --consumer --group flink  --topic ADDVERB_OPENORDER_01 --resource-pattern-type literal
 
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=10.129.36.95:2181  --add --allow-principal User:flink --consumer --group flink --topic OGG_ --resource-pattern-type prefixed
 
 
  901  unset JMX_PORT
  902  unset JMX_PROMETHEUS_PORT
  903  unset KAFKA_JMX_OPTS
 
 
-------------------------------------------------------------
 
 
Command to give prodcing rights
 
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=10.129.36.95:2181 --add --allow-principal User:ext_addverbwcs_team --producer --topic ADDVERB_OPENORDER_01 --resource-pattern-type literal
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-acls.sh --authorizer-properties zookeeper.connect=10.129.36.95:2181  --add --allow-principal User:oracle --producer --topic OGG_ --resource-pattern-type prefixed
 
 
-------------------------------------------------------------
 
 
Command to producing message
 
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-console-producer.sh --topic ADDVERB_OPENORDER_01 --producer.config /home/kafka/producer.properties --broker-list hostnamePRDabcKFK02.hostname:6667,hostnamePRDabcKFK01.hostname:6667,hostnamePRDabcKFK03.hostname:6667,hostnamePRDabcKFK04.hostname:6667,hostnamePRDabcKFK05.hostname:6667,hostnamePRDabcKFK06.hostname:6667,hostnamePRDabcKFK07.hostname:6667  
 
 
-------------------------------------------------------------
 
 
Command for consuming message
 
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-console-consumer.sh --topic macbook --consumer.config /data/kafka_certs/admin.properties --from-beginning --bootstrap-server hostnamePRDabcKFK02.hostname:6667,hostnamePRDabcKFK01.hostname:6667,hostnamePRDabcKFK03.hostname:6667,hostnamePRDabcKFK04.hostname:6667,hostnamePRDabcKFK05.hostname:6667,hostnamePRDabcKFK06.hostname:6667,hostnamePRDabcKFK07.hostname:6667  
 
 
-------------------------------------------------------------
 
 
Command to delete topic
 
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-topics.sh --delete --command-config /data/kafka_certs/admin.properties --bootstrap-server hostnamePRDabcKFK02.hostname:6667,hostnamePRDabcKFK01.hostname:6667,hostnamePRDabcKFK03.hostname:6667,hostnamePRDabcKFK04.hostname:6667,hostnamePRDabcKFK05.hostname:6667,hostnamePRDabcKFK06.hostname:6667,hostnamePRDabcKFK07.hostname:6667 --topic TEST15
 
 
-------------------------------------------------------------
 
List all topics
 
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-topics.sh --list --command-config /data/kafka_certs/admin.properties --bootstrap-server hostnameprdabckfk01.hostname:6667
 
 
-------------------------------------------------------------
 
Reset offset
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-consumer-groups.sh --bootstrap-server hostnamePRDabcKFK02.hostname:6667,hostnamePRDabcKFK01.hostname:6667,hostnamePRDabcKFK03.hostname:6667,hostnamePRDabcKFK04.hostname:6667,hostnamePRDabcKFK05.hostname:6667,hostnamePRDabcKFK06.hostname:6667,hostnamePRDabcKFK07.hostname:6667 --group test2 --reset-offsets --to-datetime 2023-11-08T11:24:24.000 --topic OGG_TEST1 --execute --command-config /home/kafka/producer.properties
 
-------------------------------------------------------------
 
Alter retention date for a topic
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-configs.sh --bootstrap-server hostnamePRDabcKFK02.hostname:6667,hostnamePRDabcKFK01.hostname:6667,hostnamePRDabcKFK03.hostname:6667,hostnamePRDabcKFK04.hostname:6667,hostnamePRDabcKFK05.hostname:6667,hostnamePRDabcKFK06.hostname:6667,hostnamePRDabcKFK07.hostname:6667 --alter --add-config retention.ms=259200000 --entity-type topics --entity-name new_test4 --command-config /data/kafka_certs/admin.properties
 
-------------------------------------------------------------
 
Delete a topic
 
/home/kafka/kafka_2.13-3.4.0/bin/kafka-topics.sh  --command-config /data/kafka_certs/admin.properties --bootstrap-server hostnamePRDabcKFK01.hostname:6667,hostnamePRDabcKFK02.hostname:6667,hostnamePRDabcKFK03.hostname:6667,hostnamePRDabcKFK04.hostname:6667,hostnamePRDabcKFK05.hostname:6667,hostnamePRDabcKFK06.hostname:6667,hostnamePRDabcKFK07.hostname:6667 --delete --topic new_test4
----------- 

Get offset for topic
##to convert ist to utc
date -u -d "2025-01-15 00:00:00 IST" +"%Y-%m-%d %H:%M:%S"

converted - 2025-01-14 18:30:00

2025-01-14T18:30:00


##convert time to epoch in kafka
date -u -d "2025-01-14T18:30:00" +%s000 -> 1736879400000



final command
./kafka-run-class.sh kafka.tools.GetOffsetShell --topic V72_abc_1P_BAG_REASON --time 1736879400000  --command-config /data1/kafka_certs/admin.properties --bootstrap-server  hostnameabcdlkkfk01.hostname:6667,hostnameabcdlkkfk02.hostname:6667,hostnameabcdlkkfk03.hostname:6667

    
