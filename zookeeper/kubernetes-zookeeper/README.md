# 简介
本镜像改自apache zookeeper官方镜像
# 镜像地址
[kubernetes-zookeeper](https://github.com/nucfox/docker_images/tree/main/zookeeper/kubernetes-zookeeper)
# Build
```bash
docker build -t kubernetes-zookeeper:3.8.3-jre-11
```

# 变量含义
- ZOO\_SERVERS\_NUM: 要部署的zookeeper服务器数量，用于生成myid和server列表。默认值"1"  
- ZOO\_CLIENT\_PORT: 客户端端口  
- ZOO\_SERVER\_PORT: 用于follower连接leader同步数据的端口  
- ZOO\_ELECTION\_PORT: 用于选举的端口  
- ZOO\_CONFTMP\_DIR: 临时存储配置的路径。默认值"/conftmp"  
- ZOO\_CONF\_DIR: zookeeper配置目录  
- ZOO\_TLS\_ENABLE: TLS开关，默认false。开启后server段不设置clientPort，需要自行在zoo.cfg指定TLS端口。  

其它环境变量与官方文档一致  

# 镜像使用方法
该镜像主要用于kubernetes的statefulset控制器部署zookeeper用，管理员需要把配置文件设置在ZOO\_CONFTMP\_DIR变量定义的路径，通过脚本设置zookeeper配置到ZOO\_CONF\_DIR变量定义的目录。  

## zoostate.cfg
zoostate.cfg的作用是分配哪些服务器是participant哪些是observer  
格式为:  
```conf
server:1:participant
server:2:participant
server:3:participant
server:4:observer
```
分为三列第一列和第二列均无实际意义只是为了与原配置server保持格式大致一致，第二列可以可以只管看到有多少个服务器，第三列是实际要使用的值，participant表示这个服务器参与投票和过半写机制，observer表示观察服务器。  

## logback.xml
logback.xml为zookeeper日志配置文件，不做介绍。  
如果不设置logback.xml，默认内容如下:  
```xml
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
```

## zoo.cfg
这个配置文件在这个镜像里比较特殊，server字段不能被设置，如果设置将导致zookeeper异常，server字段由脚本通过zoostate.cfg定义的内容自动添加。 

