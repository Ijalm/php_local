pipeline {
    agent any

    environment {
        REGISTRY = 'docker.io/library'
        IMAGE_NAME = 'tirreno'
        // Updated to Minikube's standard internal cluster IP address
        HOST_GATEWAY = '192.168.49.2'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Setup Kubeconfig') {
            steps {
                echo 'Configuring Kubernetes API access parameters...'
                withCredentials([string(credentialsId: 'k8s-token', variable: 'K8S_TOKEN')]) {
                    sh '''
                    kubectl config set-cluster minikube --server=https://${HOST_GATEWAY}:8443 --insecure-skip-tls-verify=true
                    kubectl config set-credentials jenkins-admin --token=$K8S_TOKEN
                    kubectl config set-context minikube --cluster=minikube --user=jenkins-admin
                    kubectl config use-context minikube
                    '''
                }
            }
        }

        stage('Save Dockerfile') {
            steps {
                echo 'Saving Dockerfile and k8s manifests...'
                sh '''
                cp Dockerfile ${WORKSPACE}/../tirreno.Dockerfile
                cp -r k8s ${WORKSPACE}/../k8s_backup
                '''
            }
        }

        stage('Checkout Tirreno') {
            steps {
                echo 'Cloning Tirreno source code...'
                git branch: 'master', url: 'https://github.com/tirrenotechnologies/tirreno.git'
                sh '''
                cp ${WORKSPACE}/../tirreno.Dockerfile Dockerfile
                rm -rf k8s
                cp -r ${WORKSPACE}/../k8s_backup k8s
                ls -la k8s/
                '''
            }
        }

        stage('Composer Install') {
            steps {
                echo 'Installing Composer dependencies...'
                sh '''
                php -v
                curl -sS https://getcomposer.org/installer | php
                php composer.phar install --no-dev --optimize-autoloader --ignore-platform-req=ext-mbstring --ignore-platform-req=ext-dom --ignore-platform-req=ext-simplexml
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_NAME}:${BUILD_NUMBER}"
                sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                sh '''
                kubectl config set-cluster minikube --server=https://${HOST_GATEWAY}:8443 --insecure-skip-tls-verify=true
                kubectl set image deployment/php-local php-local=${IMAGE_NAME}:${BUILD_NUMBER} || true
                kubectl apply --validate=false -f k8s/deployment.yaml
                '''
            }
        }
    }

    post {
        always {
            sh 'docker image prune -f'
        }
        failure {
            echo 'Pipeline failed. Check logs above.'
            sh '''
            kubectl config set-cluster minikube --server=https://${HOST_GATEWAY}:8443 --insecure-skip-tls-verify=true
            kubectl rollout undo deployment/php-local || true
            '''
        }
    }
}
