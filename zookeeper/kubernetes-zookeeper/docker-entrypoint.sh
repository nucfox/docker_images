#!/bin/bash

set -e

#ZOO_SERVERS="server:1:participant server:2:participant server:3:participant server:4:observer server:5:observer server:6:participant"
#ZOO_SERVERS_NUM=6
ZOOSTATE_ARRAY=()
CLIENT_PORT=${ZOO_CLIENT_PORT:-2181}
SERVER_PORT=${ZOO_SERVER_PORT:-2888}
ELECTION_PORT=${ZOO_ELECTION_PORT:-3888}
USER=`whoami`
HOST=`hostname -s`
DOMAIN=`hostname -d`
SERVERS_NUM=${ZOO_SERVERS_NUM:-1}
TMP_DIR=${ZOO_CONFTMP_DIR:-"/conftmp"}

# Allow the container to be started with `--user`
if [[ "$1" = 'zkServer.sh' && "$(id -u)" = '0' ]]; then
    chown -R zookeeper "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_LOG_DIR"
    exec gosu zookeeper "$0" "$@"
fi

if [[ ! -f "$TMP_DIR/zoostate.cfg" ]]; then
    if [[ -z $ZOO_SERVERS ]]; then
        ZOO_SERVERS="server:1:participant"
    fi
    for server in $ZOO_SERVERS; do
        ZOOSTATE_ARRAY+=("$server")
    done
else
    while IFS= read -r line
    do
        if [[ $line = \#* ]] || [[ -z $line ]]; then
            continue
        fi
        ZOOSTATE_ARRAY+=("$line")
    done < "$TMP_DIR/zoostate.cfg"
fi

function check_zoostate() {
    echo ---- ZOOSTATE_ARRAY BEGIN ----
    for i in "${ZOOSTATE_ARRAY[@]}"
    do
      echo $i
    done
    echo ---- ZOOSTATE_ARRAY END ----
    echo ${SERVERS_NUM}
    if [ ${#ZOOSTATE_ARRAY[@]} -ne ${SERVERS_NUM} ]; then
        echo "The number of lines in the Zookeeper state does not match the number of servers."
        exit 1
    fi
    for item in "${ZOOSTATE_ARRAY[@]}"
    do
        third_column_value=$(echo "$item" | awk -F: '{print $3}')
        if [ "$third_column_value" != "participant" ] && [ "$third_column_value" != "observer" ]; then
            echo "The value in the third column of the Zookeeper state configuration file can only be 'participant' or 'observer'."
            exit 1
        fi
    done
}

function print_servers() {
    for (( i=1; i<=$SERVERS_NUM; i++ ))
    do
        if [[ "$(echo ${ZOOSTATE_ARRAY[$((i-1))]} | awk -F: '{print $3}')" = "observer" ]]; then
            echo "server.$i=$NAME-$((i-1)).$DOMAIN:$SERVER_PORT:$ELECTION_PORT:observer;$CLIENT_PORT"
        else
            echo "server.$i=$NAME-$((i-1)).$DOMAIN:$SERVER_PORT:$ELECTION_PORT;$CLIENT_PORT"
        fi
    done
}

function create_zoocfg() {
if [[ -f "$TMP_DIR/zoo.cfg" ]]; then
    cp -L -f "$TMP_DIR/zoo.cfg" "$ZOO_CONF_DIR/zoo.cfg"
fi
}

function create_logback() {
if [[ -f "$TMP_DIR/logback.xml" ]]; then
    cp -L -f "$TMP_DIR/logback.xml" "$ZOO_CONF_DIR/logback.xml"
else
cat > logback.xml << 'EOF'
<configuration>
  <property name="zookeeper.console.threshold" value="INFO" />
  <property name="zookeeper.log.dir" value="." />
  <property name="zookeeper.log.file" value="zookeeper.log" />
  <property name="zookeeper.log.threshold" value="INFO" />
  <property name="zookeeper.log.maxfilesize" value="256MB" />
  <property name="zookeeper.log.maxbackupindex" value="20" />
  <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n</pattern>
    </encoder>
    <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
      <level>${zookeeper.console.threshold}</level>
    </filter>
  </appender>
  <root level="INFO">
    <appender-ref ref="CONSOLE" />
  </root>
</configuration>
EOF
fi
}

check_zoostate
create_zoocfg
create_logback

if [[ $HOST =~ (.*)-([0-9]+)$ ]]; then
    NAME=${BASH_REMATCH[1]}
    ORD=${BASH_REMATCH[2]}
else
    echo "Fialed to parse name and ordinal of Pod"
    exit 1
fi

# Generate the config only if it doesn't exist
if [[ ! -f "$ZOO_CONF_DIR/zoo.cfg" ]]; then
    CONFIG="$ZOO_CONF_DIR/zoo.cfg"
    {
        echo "dataDir=$ZOO_DATA_DIR"
        echo "dataLogDir=$ZOO_DATA_LOG_DIR"

        echo "tickTime=$ZOO_TICK_TIME"
        echo "initLimit=$ZOO_INIT_LIMIT"
        echo "syncLimit=$ZOO_SYNC_LIMIT"

        echo "autopurge.snapRetainCount=$ZOO_AUTOPURGE_SNAPRETAINCOUNT"
        echo "autopurge.purgeInterval=$ZOO_AUTOPURGE_PURGEINTERVAL"
        echo "maxClientCnxns=$ZOO_MAX_CLIENT_CNXNS"
        echo "standaloneEnabled=$ZOO_STANDALONE_ENABLED"
        echo "admin.enableServer=$ZOO_ADMINSERVER_ENABLED"
    } >> "$CONFIG"
    
    print_servers >> $CONFIG
    
    if [[ -n $ZOO_4LW_COMMANDS_WHITELIST ]]; then
        echo "4lw.commands.whitelist=$ZOO_4LW_COMMANDS_WHITELIST" >> "$CONFIG"
    fi

    for cfg_extra_entry in $ZOO_CFG_EXTRA; do
        echo "$cfg_extra_entry" >> "$CONFIG"
    done
else
  CONFIG="$ZOO_CONF_DIR/zoo.cfg"
  print_servers >> $CONFIG
fi

MY_ID=$((ORD+1))

if [ ! -f "$ZOO_DATA_DIR/myid" ]; then
    echo $MY_ID >> "$ZOO_DATA_DIR/myid"
fi

exec "$@"
