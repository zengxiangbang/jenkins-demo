#FROM tomcat
#FROM tomcat:7.0.91-jre8-alpine
#FROM harbor2.mail.10086.cn/public/tomcat:8.5.37-jre8-alpine
FROM harbor2.mail.10086.cn/public/tomcat8_jre8:latest
ADD target/demo.war /usr/local/tomcat/webapps/demo.war
