pipeline {
  agent any
  environment {
    GOPROXY = 'https://goproxy.cn,direct'
  }
  tools {
    go 'go'
  }
  stages {
    stage('Clone mysql cluster') {
      steps {
        git(url: scm.userRemoteConfigs[0].url, branch: '$BRANCH_NAME', changelog: true, credentialsId: 'KK-github-key', poll: true)
      }
    }

    stage('Build mysql image') {
      when {
        expression { BUILD_TARGET == 'true' }
      }
      steps {
        sh 'mkdir -p .docker-tmp; cp /usr/bin/consul .docker-tmp'
        sh(returnStdout: true, script: '''
          images=`docker images | grep entropypool | grep mysql | awk '{ print $3 }'`
          for image in $images; do
            docker rmi $image -f
          done
        '''.stripIndent())
        sh 'docker build -t $DOCKER_REGISTRY/entropypool/mysql:5.7.35.12-web3eye .'
      }
    }

    stage('Release mysql image') {
      when {
        expression { RELEASE_TARGET == 'true' }
      }
      steps {
        sh(returnStdout: true, script: '''
          set +e
          while true; do
            docker push $DOCKER_REGISTRY/entropypool/mysql:5.7.35.12-web3eye
            if [ $? -eq 0 ]; then
              break
            fi
          done
          set -e
        '''.stripIndent())
      }
    }

    stage('Switch to current cluster') {
      steps {
        sh 'cd /etc/kubeasz; ./ezctl checkout $TARGET_ENV'
      }
    }

    stage('Deploy mysql cluster') {
      when {
        expression { DEPLOY_TARGET == 'true' }
      }
      steps {
        sh (returnStdout: true, script: '''
          export MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
          envsubst < k8s/secret.yaml | kubectl apply -f -
        '''.stripIndent())
        sh 'kubectl apply -k k8s'
      }
    }

    stage('Config apollo') {
      when {
        expression { CONFIG_TARGET == 'true' }
      }
      steps {
        sh 'rm .apollo-base-config -rf'
        sh 'git clone https://github.com/NpoolPlatform/apollo-base-config.git .apollo-base-config'
        sh 'cd .apollo-base-config; ./apollo-base-config.sh $APP_ID $TARGET_ENV mysql-npool-top'
        sh 'cd .apollo-base-config; ./apollo-item-config.sh $APP_ID $TARGET_ENV mysql-npool-top username root'
        sh 'cd .apollo-base-config; ./apollo-item-config.sh $APP_ID $TARGET_ENV mysql-npool-top password $MYSQL_ROOT_PASSWORD'
      }
    }

    stage('Execute base sql') {
      when {
        expression { DEPLOY_TARGET == 'true' }
      }
      steps {
        sh (returnStdout: true, script: '''
            export MYSQL_EXPORTER_PASSWORD=$MYSQL_EXPORTER_PASSWORD
            PASSWORD=`kubectl get secret --namespace "default" mysql-password-secret -o jsonpath="{.data.rootpassword}" | base64 --decode`
            envsubst < ./sql/base.sql | kubectl exec -it -n default mysql-0 -- mysql -uroot -p$PASSWORD
            kubectl create secret generic mysql-exporter-password-secret --from-literal=password=$MYSQL_EXPORTER_PASSWORD -n monitor || echo "secret already exists"
            '''.stripIndent())
      }
    }

  }

  post('Report') {
    fixed {
      script {
        sh(script: 'bash $JENKINS_HOME/wechat-templates/send_wxmsg.sh fixed')
     }
      script {
        // env.ForEmailPlugin = env.WORKSPACE
        emailext attachmentsPattern: 'TestResults\\*.trx',
        body: '${FILE,path="$JENKINS_HOME/email-templates/success_email_tmp.html"}',
        mimeType: 'text/html',
        subject: currentBuild.currentResult + " : " + env.JOB_NAME,
        to: '$DEFAULT_RECIPIENTS'
      }
     }
    success {
      script {
        sh(script: 'bash $JENKINS_HOME/wechat-templates/send_wxmsg.sh successful')
     }
      script {
        // env.ForEmailPlugin = env.WORKSPACE
        emailext attachmentsPattern: 'TestResults\\*.trx',
        body: '${FILE,path="$JENKINS_HOME/email-templates/success_email_tmp.html"}',
        mimeType: 'text/html',
        subject: currentBuild.currentResult + " : " + env.JOB_NAME,
        to: '$DEFAULT_RECIPIENTS'
      }
     }
    failure {
      script {
        sh(script: 'bash $JENKINS_HOME/wechat-templates/send_wxmsg.sh failure')
     }
      script {
        // env.ForEmailPlugin = env.WORKSPACE
        emailext attachmentsPattern: 'TestResults\\*.trx',
        body: '${FILE,path="$JENKINS_HOME/email-templates/fail_email_tmp.html"}',
        mimeType: 'text/html',
        subject: currentBuild.currentResult + " : " + env.JOB_NAME,
        to: '$DEFAULT_RECIPIENTS'
      }
     }
    aborted {
      script {
        sh(script: 'bash $JENKINS_HOME/wechat-templates/send_wxmsg.sh aborted')
     }
      script {
        // env.ForEmailPlugin = env.WORKSPACE
        emailext attachmentsPattern: 'TestResults\\*.trx',
        body: '${FILE,path="$JENKINS_HOME/email-templates/fail_email_tmp.html"}',
        mimeType: 'text/html',
        subject: currentBuild.currentResult + " : " + env.JOB_NAME,
        to: '$DEFAULT_RECIPIENTS'
      }
     }
  }
}
