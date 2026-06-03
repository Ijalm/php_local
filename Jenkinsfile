pipeline {
    agent any
    environment {
        APP_NAME       = 'tirreno'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        IMAGE_NAME     = "${APP_NAME}:${IMAGE_TAG}"
        CONTAINER_NAME = 'tirreno-container'
        APP_PORT       = '9090'
        NEXUS_REGISTRY = 'localhost:8082'
        NEXUS_IMAGE    = "localhost:8082/${APP_NAME}:${IMAGE_TAG}"
    }
    stages {
        stage('Save Dockerfile') {
            steps {
                echo 'Saving Dockerfile and k8s manifests before workspace overwrite...'
                sh '''
                    cp Dockerfile $WORKSPACE/../tirreno.Dockerfile
                    cp -r k8s $WORKSPACE/../k8s_backup
                '''
            }
        }
        stage('Checkout Tirreno') {
            steps {
                echo 'Cloning tirreno source code...'
                git branch: 'master',
                    url: 'https://github.com/tirrenotechnologies/tirreno.git'
                sh '''
                    cp $WORKSPACE/../tirreno.Dockerfile Dockerfile
                    rm -rf k8s
                    cp -r $WORKSPACE/../k8s_backup k8s
                    ls -la k8s/
                '''
            }
        }
        stage('Composer Install') {
            steps {
                echo 'Installing Composer dependencies...'
                sh '''
                    php -v || true
                    curl -sS https://getcomposer.org/installer | php
                    php composer.phar install \
                        --no-dev \
                        --optimize-autoloader \
                        --ignore-platform-req=ext-mbstring \
                        --ignore-platform-req=ext-dom \
                        --ignore-platform-req=ext-simplexml \
                        || true
                '''
            }
        }
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_NAME}"
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }
        // stage('Push to Nexus') {
        //     steps {
        //         echo "Pushing image to Nexus: ${NEXUS_IMAGE}"
        //         withCredentials([usernamePassword(
        //             credentialsId: 'nexus-credentials',
        //             usernameVariable: 'NEXUS_USER',
        //             passwordVariable: 'NEXUS_PASS'
        //         )]) {
        //             sh """
        //                 echo "\$NEXUS_PASS" | docker login ${NEXUS_REGISTRY} \
        //                     -u "\$NEXUS_USER" --password-stdin
        //                 docker tag ${IMAGE_NAME} ${NEXUS_IMAGE}
        //                 docker push ${NEXUS_IMAGE}
        //                 docker logout ${NEXUS_REGISTRY}
        //             """
        //         }
        //     }
        // }
        stage('Push to Nexus') {
    steps {
        echo "Pushing image to Nexus: ${NEXUS_IMAGE}"
        withCredentials([usernamePassword(
            credentialsId: 'nexus-credentials',
            usernameVariable: 'NEXUS_USER',
            passwordVariable: 'NEXUS_PASS'
        )]) {
            sh """
                echo "\$NEXUS_PASS" | docker login localhost:8082 \
                    -u "\$NEXUS_USER" --password-stdin
                echo "\$NEXUS_PASS" | docker login 192.168.100.37:8082 \
                    -u "\$NEXUS_USER" --password-stdin
                docker tag ${IMAGE_NAME} ${NEXUS_IMAGE}
                docker tag ${IMAGE_NAME} 192.168.100.37:8082/tirreno:latest
                docker push ${NEXUS_IMAGE}
                docker push 192.168.100.37:8082/tirreno:latest
                docker logout localhost:8082
                docker logout 192.168.100.37:8082
            """
        }
    }
}
        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                sh '''
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl rollout status deployment/php-local
                '''
            }
        }
    }
    post {
        success {
            echo "Deployment successful! Tirreno is running."
        }
        failure {
            echo 'Pipeline failed. Check logs above.'
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
