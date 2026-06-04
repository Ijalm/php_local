pipeline {
    agent any

    environment {
        IMAGE = "localhost:8082/php-app"
        TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/YOUR_REPO/php_local.git'
            }
        }

        stage('Build Image') {
            steps {
                sh "docker build -t $IMAGE:$TAG ."
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                        echo $PASS | docker login localhost:8082 -u $USER --password-stdin
                        docker push $IMAGE:$TAG
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    kubectl set image deployment/php-app php-app=$IMAGE:$TAG
                    kubectl rollout status deployment/php-app
                """
            }
        }
    }
}
