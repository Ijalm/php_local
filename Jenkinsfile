pipeline {
    agent any

    environment {
        APP_NAME       = 'tirreno'
        IMAGE_TAG      = "${BUILD_NUMBER}"
        IMAGE_NAME     = "${APP_NAME}:${IMAGE_TAG}"
        CONTAINER_NAME = 'tirreno-container'
        APP_PORT       = '8080'

        NEXUS_URL      = 'http://localhost:8081'
        NEXUS_REPO     = 'docker-hosted'
        NEXUS_IMAGE    = "localhost:8081/repository/${NEXUS_REPO}/${APP_NAME}:${IMAGE_TAG}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Cloning tirreno repository...'
                git branch: 'master',
                    url: 'https://github.com/tirrenotechnologies/tirreno.git'
            }
        }

        stage('Composer Install') {
            steps {
                echo 'Installing Composer locally in workspace...'
                sh '''
                    php -v || true
                    curl -sS https://getcomposer.org/installer | php
                    php composer.phar --version
                    php composer.phar install || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_NAME}"
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Push to Nexus Docker Registry') {
            steps {
                echo "Pushing image to Nexus: ${NEXUS_IMAGE}"
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                        echo "$NEXUS_PASS" | docker login localhost:8081 \
                            -u "$NEXUS_USER" --password-stdin

                        docker tag ${IMAGE_NAME} ${NEXUS_IMAGE}
                        docker push ${NEXUS_IMAGE}
                        docker logout localhost:8081
                    '''
                }
            }
        }

        stage('Deploy Locally') {
            steps {
                echo 'Deploying tirreno container...'
                sh '''
                    docker stop tirreno-container || true
                    docker rm tirreno-container || true

                    docker run -d \
                        --name tirreno-container \
                        -p 8080:80 \
                        --restart unless-stopped \
                        -e DB_HOST=host.docker.internal \
                        -e DB_PORT=5432 \
                        -e DB_NAME=tirreno \
                        -e DB_USER=tirreno \
                        -e DB_PASSWORD=changeme \
                        localhost:8081/repository/docker-hosted/tirreno:${BUILD_NUMBER}
                '''
            }
        }
    }

    post {
        success {
            echo "Deployment successful! Tirreno running at http://localhost:${APP_PORT}"
        }
        failure {
            echo 'Pipeline failed. Check logs above.'
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
