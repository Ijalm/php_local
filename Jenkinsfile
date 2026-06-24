pipeline {
    agent any
    environment {
        APP_NAME           = 'tirreno'
        IMAGE_TAG          = "${BUILD_NUMBER}"
        IMAGE_NAME         = "${APP_NAME}:${IMAGE_TAG}"
        
        // Updated to use the Docker bridge IP instead of localhost
        NEXUS_REGISTRY     = '172.17.0.1:8082'
        NEXUS_IMAGE        = "172.17.0.1:8082/${APP_NAME}:${IMAGE_TAG}"
        NEXUS_IMAGE_LATEST = "172.17.0.1:8082/${APP_NAME}:latest"
    }
    stages {
        stage('Save Dockerfile') {
            steps {
                echo 'Saving Dockerfile and k8s manifests...'
                sh '''
                    cp Dockerfile $WORKSPACE/../tirreno.Dockerfile
                    cp -r k8s $WORKSPACE/../k8s_backup
                '''
            }
        }
        stage('Checkout Tirreno') {
            steps {
                echo 'Cloning Tirreno source code...'
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
        stage('Push to Nexus') {
            steps {
                echo "Pushing image to Nexus: ${NEXUS_IMAGE}"
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh """
                        echo "\$NEXUS_PASS" | docker login ${NEXUS_REGISTRY} \
                            -u "\$NEXUS_USER" --password-stdin

                        docker tag ${IMAGE_NAME} ${NEXUS_IMAGE}
                        docker push ${NEXUS_IMAGE}

                        docker tag ${IMAGE_NAME} ${NEXUS_IMAGE_LATEST}
                        docker push ${NEXUS_IMAGE_LATEST} || \
                            echo "WARNING: Could not push latest tag. Continuing..."

                        docker logout ${NEXUS_REGISTRY}
                    """
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                sh """
                    kubectl set image deployment/php-local \
                        php-local=${NEXUS_IMAGE} --record || true

                    kubectl apply --validate=false -f k8s/deployment.yaml
                    kubectl apply --validate=false -f k8s/service.yaml

                    kubectl rollout status deployment/php-local --timeout=120s
                """
            }
        }
    }
    post {
        success {
            echo "Deployment successful! Tirreno ${IMAGE_TAG} is running."
        }
        failure {
            echo 'Pipeline failed. Check logs above.'
            sh 'kubectl rollout undo deployment/php-local || true'
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
