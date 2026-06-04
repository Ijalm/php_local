pipeline {
  agent any

  environment {
    REGISTRY = "192.168.100.37:8082"
    IMAGE = "php-app:1"
  }

  stages {

    stage('Checkout') {
      steps {
        git credentialsId: 'github-token',
            url: 'https://github.com/Ijalm/php_local.git',
            branch: 'main'
      }
    }

    stage('Build') {
      steps {
        sh "docker build -t $REGISTRY/$IMAGE ."
      }
    }

    stage('Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'nexus', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
          sh '''
            echo $PASS | docker login $REGISTRY -u $USER --password-stdin
            docker push $REGISTRY/$IMAGE
          '''
        }
      }
    }

    stage('Deploy') {
      steps {
        sh "kubectl apply --validate=false -f k8s/"
        sh "kubectl rollout restart deployment php-local"
      }
    }
  }
}
