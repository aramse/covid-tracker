pipeline {
  agent any
  options { ansiColor('xterm') }
  
  environment {
    COMMIT_HASH = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
    F8_TAG = "$BRANCH_NAME-$BUILD_ID-$COMMIT_HASH"
    F8_ENVIRONMENT = "$BRANCH_NAME"
    F8_ENV_TYPE = "$BRANCH_NAME"
  }

  stages {
    stage('Build') {
      steps {
        withDockerRegistry([url: 'https://gcr.io', credentialsId: 'gcr']) {
          sh 'f8 build --push'
        }
      }
    }
    stage('Deploy') {
      steps {
        sh 'f8 deploy'
      }
    }
    stage('Test') {
      steps {
        sh 'f8 test'
      }
    }
  }
  post {
    success {
      slackSend color: "#4ee44e", message: "${JOB_NAME} <${BUILD_URL}/display/redirect|Build #${BUILD_NUMBER}> Succeeded"
    }
    failure {
      slackSend color: "#FF0000", message: "${JOB_NAME} <${BUILD_URL}/display/redirect|Build #${BUILD_NUMBER}> Failed"
    }
  }
}
