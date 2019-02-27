#FROM tomcat
FROM tomcat:7.0.91-jre8-alpine
#harbor2.mail.10086.cn/public/tomcat7_jre7
ADD target/demo.war /usr/local/tomcat/webapps/demo.war
