pipeline{
    //定义参数化构建
       parameters {		 
		string(name: 'origin_repo', defaultValue: 'harbor2.mail.10086.cn', description: 'docker私仓地址')
        string(name: 'repo', defaultValue: "${JOB_NAME}", description: 'docker镜像名')
        choice(name: 'envs', choices: ['prod', 'dev', 'test', 'grey'], description: 'prod    --生产线,  master分支\ndev      --开发线,  dev分支\ntest      --测试线,  test分支\ngrey     --灰度线,  grey分支')
        }
      // 定义groovy脚本中使用的环境变量
      environment{
        // 本示例中使用DEPLOY_TO_K8S变量来决定把应用部署到哪套容器集群环境中，如“Production Environment”， “Staging001 Environment”等
        //    IMAGE_TAG =  sh(returnStdout: true,script: 'echo $image_tag').trim()
        // 来来作为 使用build_number作为image_tag
        //  IMAGE_TAG =  sh(returnStdout: true,script: 'echo $BUILD_NUMBER').trim()  
        //  BRANCH =  sh(returnStdout: true,script: 'echo $GIT_BRANCH').trim()
        IMAGE_TAG = "${BUILD_NUMBER}"
        ENVS = "${params.envs}"
        BRANCH = sh(returnStdout: true,script: 'if [ "$envs" == "prod" ];then BRANCH=master;else BRANCH="$envs";fi ;echo $BRANCH').trim()
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
            sh "echo $BRANCH"
            sh "echo $IMAGE_TAG"
            sh "echo $ENVS"
        //   git branch: '${BRANCH}', credentialsId: '', url: 'https://github.com/zengxiangbang/jenkins-demo.git'
        
        //    script
         //       {
         //           //according jenkins job name to set git url and branch to download
         //           switch(env.GIT_BRANCH)
         //           {
         //               case "master":
         //                  branch = 'master'
		//					envs= 'prod'
         //                   break
         //               case "dev":
         //                   branch = 'dev'
		//					envs= 'dev'
         //                   break
        //                case "test":
        //                    branch = 'test'
		//					envs= 'test'
        //                    break
        //                case "grey":
        //                    branch = 'grey'
		//					envs= 'grey'
        //                    break
        //                default:
         //                   echo "############ wrong pipeline name ############"
        //                    break
        //            }
         git branch: "${BRANCH}", credentialsId: 'github', url: "https://github.com/zengxiangbang/${params.repo}.git"
        //           git branch: "${GIT_BRANCH}", credentialsId: 'github', url: "https://github.com/zengxiangbang/${params.repo}.git"
		//		 }
          }
        }

        // 添加第二个stage， 运行源码打包命令
        stage('Package'){
          steps{
              container("maven") {
                  sh "mvn package -B -DskipTests -P ${ENVS}"
                }
              
          }
        }

        // 添加第四个stage, 运行容器镜像构建和推送命令， 用到了environment中定义的groovy环境变量
        stage('Image Build And Publish'){
          steps{
              container("kaniko") {
                  sh "kaniko -f `pwd`/Dockerfile -c `pwd` --destination=${ORIGIN_REPO}/${ENVS}/${REPO}:${IMAGE_TAG}"
              }
          }
        }
        stage('部暑到kubernetes') {
        parallel {
         stage('部暑到生产环境') {
            when {
                 expression {
                 "$BRANCH" == "master"
            }
         }
             steps {
                 sh "env"
                 container('kubectl') {
                     sh "env"
                     step([$class: 'KubernetesDeploy', context: [configs: 'deployment.yaml', dockerCredentials: [[credentialsId: 'harbor2-repos', url: 'https://harbor2.mail.10086.cn']], kubeConfig: [path: ''], kubeconfigId: 'k8sCertAuth', secretName: 'harborsecret']])                    }
                    }
                }
         stage('发布到测试环境') {
             when {
                 expression {
                 "$BRANCH" == "test"
             }
                    }
             steps {
                 container('kubectl') {
                     step([$class: 'KubernetesDeploy', context: [configs: 'deployment.yaml', dockerCredentials: [[credentialsId: 'harbor2-repos', url: 'https://harbor2.mail.10086.cn']], kubeConfig: [path: ''], kubeconfigId: 'k8sCertAuth', secretName: 'harborsecret']])  
                     }
                    }
                }
            }
        }
      }
    }
