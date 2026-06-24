pipeline {
    agent any
    environment {
        APP_NAME           = 'tirreno'
        IMAGE_TAG          = "${BUILD_NUMBER}"
        IMAGE_NAME         = "${APP_NAME}:${IMAGE_TAG}"
        
        // Forces kubectl to use a clean config file inside the workspace
        KUBECONFIG         = "${WORKSPACE}/.kubeconfig"
    }
    stages {
        stage('Setup Kubeconfig') {
            steps {
                echo 'Configuring Kubernetes API access parameters...'
                withCredentials([string(credentialsId: 'jenkins-kubernetes-token', variable: 'K8S_TOKEN')]) {
                    sh """
                        kubectl config set-cluster minikube --server=https://192.168.49.2:8443 --insecure-skip-tls-verify=true
                        kubectl config set-credentials jenkins-admin --token=\${K8S_TOKEN}
                        kubectl config set-context minikube --cluster=minikube --user=jenkins-admin
                        kubectl config use-context minikube
                    """
                }
            }
        }
        stage('Save Dockerfile') {
            steps {
                echo 'Saving Dockerfile and k8s manifests...'
                sh """
                    cp Dockerfile \$WORKSPACE/../tirreno.Dockerfile
                    cp -r k8s \$WORKSPACE/../k8s_backup
                """
            }
        }
        stage('Checkout Tirreno') {
            steps {
                echo 'Cloning Tirreno source code...'
                git branch: 'master',
                    url: 'https://github.com/tirrenotechnologies/tirreno.git'
                sh """
                    cp \$WORKSPACE/../tirreno.Dockerfile Dockerfile
                    rm -rf k8s
                    cp -r \$WORKSPACE/../k8s_backup k8s
                    ls -la k8s/
                """
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
        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                sh """
                    kubectl set image deployment/php-local \
                        php-local=${IMAGE_NAME} --record || true

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
