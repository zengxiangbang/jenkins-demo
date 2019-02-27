pipeline{
      // 定义groovy脚本中使用的环境变量
      environment{
        // 本示例中使用DEPLOY_TO_K8S变量来决定把应用部署到哪套容器集群环境中，如“Production Environment”， “Staging001 Environment”等
        IMAGE_TAG =  sh(returnStdout: true,script: 'echo $image_tag').trim()
        BRANCH =  sh(returnStdout: true,script: 'echo $branch').trim()
      }

      // 定义本次构建使用哪个标签的构建环境，本示例中为 “slave-pipeline”
      agent{
        kubernetes {
            label 'slave-pipeline'
            defaultContainer 'jnlp'
            yaml """
            apiVersion: v1
            kind: Pod
            metadata:
              labels:
                app: slave-pipeline
            spec:
                nodeSelector:
#                  workload_type: spot  #阿里云竞价时使用
                containers:
                - name: kaniko
                  image: registry.cn-beijing.aliyuncs.com/acs-sample/jenkins-slave-kaniko:0.6.0
                  command:
                  - cat
                  tty: true
                  workingDir: '/home/jenkins'
                  volumeMounts:
                  - name: jenkins-docker-cfg
                    mountPath: "/home/jenkins/.docker"
                  env:
                  - name: DOCKER_CONFIG
                    value: /home/jenkins/.docker
                - name: maven
                  image: registry.cn-beijing.aliyuncs.com/acs-sample/jenkins-slave-maven:3.3.9-jdk-8-alpine
                  command:
                  - cat
                  tty: true
                  workingDir: '/home/jenkins'
                - name: kubectl
                  image: registry.cn-beijing.aliyuncs.com/acs-sample/jenkins-slave-kubectl:1.11.5
                  command:
                  - cat
                  tty: true
                  workingDir: '/home/jenkins'
                volumes:
                - name: jenkins-docker-cfg
                  secret:
                    secretName: jenkins-docker-cfg
            """
        }
    }

      // "stages"定义项目构建的多个模块，可以添加多个 “stage”， 可以多个 “stage” 串行或者并行执行
      stages{
        // 定义第一个stage， 完成克隆源码的任务
        stage('Git'){
          steps{
            git branch: '${BRANCH}', credentialsId: '', url: 'https://github.com/zengxiangbang/jenkins-demo.git'
          }
        }

        // 添加第二个stage， 运行源码打包命令
        stage('Package'){
          steps{
              container("maven") {
                  sh "mvn package -B -DskipTests"
              }
          }
        }

        // 添加第四个stage, 运行容器镜像构建和推送命令， 用到了environment中定义的groovy环境变量
        stage('Image Build And Publish'){
          steps{
              container("kaniko") {
                  sh "kaniko -f `pwd`/Dockerfile -c `pwd` --destination=${ORIGIN_REPO}/${REPO}:${IMAGE_TAG}"
              }
          }
        }
        stage('Deploy to Kubernetes') {
        parallel {
         stage('Deploy to Production Environment') {
            when {
             expression {
             "$BRANCH" == "master"
            }
         }
         steps {
             container('kubectl') {
                  step([$class: 'KubernetesDeploy', context: [configs: 'deployment.yaml', dockerCredentials: [[credentialsId: 'harbor2-repos', url: 'https://harbor2.mail.10086.cn']], kubeConfig: [path: ''], kubeconfigId: 'k8sCertAuth', secretName: 'harborsecret', ssh: [sshCredentialsId: '*', sshServer: ''], textCredentials: [certificateAuthorityData: '', clientCertificateData: '', clientKeyData: '', serverUrl: 'https://']]])                    }
                    }
                }
                stage('Deploy to Staging001 Environment') {
                    when {
                        expression {
                            "$BRANCH" == "latest"
                        }
                    }
                    steps {
                        container('kubectl') {
                       step([$class: 'KubernetesDeploy', context: [configs: 'deployment.yaml', dockerCredentials: [[credentialsId: 'harbor2-repos', url: 'https://harbor2.mail.10086.cn']], kubeConfig: [path: ''], kubeconfigId: 'k8sCertAuth', secretName: 'harborsecret', ssh: [sshCredentialsId: '*', sshServer: ''], textCredentials: [certificateAuthorityData: '', clientCertificateData: '', clientKeyData: '', serverUrl: 'https://']]])
                }
                    }
                }
            }
        }
      }
    }
