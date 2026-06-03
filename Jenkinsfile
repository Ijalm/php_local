// pipeline {
//     agent any

//     environment {
//         APP_NAME       = 'tirreno'
//         IMAGE_TAG      = "${BUILD_NUMBER}"
//         IMAGE_NAME     = "${APP_NAME}:${IMAGE_TAG}"
//         CONTAINER_NAME = 'tirreno-container'
//         APP_PORT       = '9090'
//         NEXUS_REGISTRY = 'localhost:8082'
//         NEXUS_IMAGE    = "localhost:8082/${APP_NAME}:${IMAGE_TAG}"
//     }

//     stages {

//         stage('Save Dockerfile') {
//             steps {
//                 echo 'Saving Dockerfile before workspace overwrite...'
//                 sh 'cp Dockerfile /tmp/tirreno.Dockerfile'
//             }
//         }

//         stage('Checkout Tirreno') {
//             steps {
//                 echo 'Cloning tirreno source code...'
//                 git branch: 'master',
//                     url: 'https://github.com/tirrenotechnologies/tirreno.git'
//                 sh 'cp /tmp/tirreno.Dockerfile Dockerfile'
//             }
//         }

//         stage('Composer Install') {
//             steps {
//                 echo 'Installing Composer dependencies...'
//                 sh '''
//                     php -v || true
//                     curl -sS https://getcomposer.org/installer | php
//                     php composer.phar install \
//                         --no-dev \
//                         --optimize-autoloader \
//                         --ignore-platform-req=ext-mbstring \
//                         --ignore-platform-req=ext-dom \
//                         --ignore-platform-req=ext-simplexml \
//                         || true
//                 '''
//             }
//         }

//         stage('Build Docker Image') {
//             steps {
//                 echo "Building Docker image: ${IMAGE_NAME}"
//                 sh "docker build -t ${IMAGE_NAME} ."
//             }
//         }

//         stage('Push to Nexus') {
//             steps {
//                 echo "Pushing image to Nexus: ${NEXUS_IMAGE}"
//                 withCredentials([usernamePassword(
//                     credentialsId: 'nexus-credentials',
//                     usernameVariable: 'NEXUS_USER',
//                     passwordVariable: 'NEXUS_PASS'
//                 )]) {
//                     sh """
//                         echo "\$NEXUS_PASS" | docker login ${NEXUS_REGISTRY} \
//                             -u "\$NEXUS_USER" --password-stdin
//                         docker tag ${IMAGE_NAME} ${NEXUS_IMAGE}
//                         docker push ${NEXUS_IMAGE}
//                         docker logout ${NEXUS_REGISTRY}
//                     """
//                 }
//             }
//         }

//   //      stage('Deploy Locally') {
//   //          steps {
//   //             echo 'Deploying tirreno container from Nexus...'
//    //             sh """
//   //                  docker stop ${CONTAINER_NAME} || true
//  //                   docker rm   ${CONTAINER_NAME} || true
// //
//  //                   docker run -d \
//  //                       --name ${CONTAINER_NAME} \
//  //                       -p ${APP_PORT}:80 \
//  //                       --restart unless-stopped \
//  //                       -e DB_HOST=host.docker.internal \
//  //                       -e DB_PORT=5432 \
//  //                       -e DB_NAME=tirreno \
// //                        -e DB_USER=tirreno \
// //                        -e DB_PASSWORD=changeme \
// //                        ${NEXUS_IMAGE}
// //                """
// //            }
// //        }
//   }
// stage('Deploy to Kubernetes') {
//     steps {
//         sh '''
//             kubectl apply -f k8s/deployment.yaml
//             kubectl apply -f k8s/service.yaml
//             kubectl rollout status deployment/php-local
//         '''
//     }
// }
//     post {
//         success {
//             echo "Deployment successful! Tirreno running at http://localhost:${APP_PORT}"
//         }
//         failure {
//             echo 'Pipeline failed. Check logs above.'
//         }
//         always {
//             sh 'docker image prune -f || true'
//         }
//     }
// }
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
                echo 'Saving Dockerfile before workspace overwrite...'
                sh 'cp Dockerfile /tmp/tirreno.Dockerfile'
            }
        }
        stage('Checkout Tirreno') {
            steps {
                echo 'Cloning tirreno source code...'
                git branch: 'master',
                    url: 'https://github.com/tirrenotechnologies/tirreno.git'
                sh 'cp /tmp/tirreno.Dockerfile Dockerfile'
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
                        docker logout ${NEXUS_REGISTRY}
                    """
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
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
            echo "Deployment successful! Tirreno running at http://localhost:${APP_PORT}"
        }
        failure {
            sh 'docker image prune -f || true'
            echo 'Pipeline failed. Check logs above.'
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
