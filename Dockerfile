FROM tomcat
#harbor2.mail.10086.cn/public/tomcat7_jre7
ADD target/demo.war /usr/local/tomcat/webapps/demo.war
