pipeline {
    agent any
    
    environment {
        REMOTE_HOST = "$REMOTE_HOST"          // Remote server IP / hostname
        REMOTE_PATH = "$REMOTE_PATH"      // Remote docker-compose dizini
        DOCKER_IMAGE = "rdplone/zot-arm32v7:latest" // Docker Hub imajı
        COMPOSE_FILE = "docker-compose.yaml"
    }
    
    stages {
        stage('🔗 Connect to Remote Host') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$REMOTE_HOST 'echo "SSH connection successful"'
                    """
                }
            }
        }
        
        stage('📁 Setup Remote Directory') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$REMOTE_HOST '
                            mkdir -p \$REMOTE_PATH
                        '
                    """
                }
            }
        }
        
        stage('📥 Copy Docker Compose File') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    script {
                        // GitHub'dan docker-compose.yaml dosyasını al
                        def repoUrl = 'https://github.com/Rdplone/zot-arm32v7.git'
                        def rawUrl = repoUrl.replace('.git','').replace('github.com','raw.githubusercontent.com') + '/main/' + env.COMPOSE_FILE
                        
                        echo "Downloading docker-compose.yaml from: ${rawUrl}"
                        
                        sh """
                            curl -fsSL '${rawUrl}' -o docker-compose.yaml
                            sshpass -p \$SSH_PASS scp -o StrictHostKeyChecking=no docker-compose.yaml \$SSH_USER@\$REMOTE_HOST:\$REMOTE_PATH/
                            rm -f docker-compose.yaml
                        """
                    }
                }
            }
        }
        
        stage('🛑 Stop and Clean') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$REMOTE_HOST '
                            cd \$REMOTE_PATH
                            docker-compose down || true
                            docker system prune -f
                            echo "Services stopped and system cleaned"
                        '
                    """
                }
            }
        }
        
        stage('🚀 Deploy New Version') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$REMOTE_HOST '
                            cd \$REMOTE_PATH
                            sed -i "s|image:.*|image: \$DOCKER_IMAGE|" docker-compose.yaml
                            docker-compose pull
                            docker-compose up -d
                            sleep 5
                            docker-compose ps
                            echo "Deployment completed successfully"
                        '
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}
