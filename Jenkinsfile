pipeline {
    agent any

    environment {
        APP_NAME       = 'tirreno'
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
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

        stage('Configure Composer to use Nexus') {
            steps {
                echo 'Installing Composer and pointing to Nexus proxy...'
                sh """
                    curl -sS https://getcomposer.org/installer | php
                    mv composer.phar /usr/local/bin/composer
                    composer config --global repositories.nexus \
                        composer ${NEXUS_URL}/repository/composer-proxy/
                    composer config --global secure-http false
                """
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
                    sh """
                        echo "$NEXUS_PASS" | docker login ${NEXUS_URL} \
                            -u "$NEXUS_USER" --password-stdin
                        docker tag ${IMAGE_NAME} ${NEXUS_IMAGE}
                        docker push ${NEXUS_IMAGE}
                        docker logout ${NEXUS_URL}
                    """
                }
            }
        }

        stage('Deploy Locally') {
            steps {
                echo 'Deploying tirreno container...'
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm   ${CONTAINER_NAME} || true

                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        -p ${APP_PORT}:80 \
                        --restart unless-stopped \
                        -e DB_HOST=host.docker.internal \
                        -e DB_PORT=5432 \
                        -e DB_NAME=tirreno \
                        -e DB_USER=tirreno \
                        -e DB_PASSWORD=changeme \
                        ${NEXUS_IMAGE}
                """
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
