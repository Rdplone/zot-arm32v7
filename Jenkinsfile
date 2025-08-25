pipeline {
    agent any
    
    environment {
        GIT_REPO = "https://github.com/Rdplone/zot-arm32v7.git"
        COMPOSE_FILE = "docker-compose.yml"
    }
    
    stages {
        stage('Install sshpass') {
            steps {
                sh """
                    if ! command -v sshpass &> /dev/null; then
                        echo "sshpass not found, installing..."
                        sudo apt-get update
                        sudo apt-get install -y sshpass
                    else
                        echo "sshpass already installed"
                    fi
                """
            }
        }

        stage('Checkout') {
            steps {
                git branch: 'main', url: "${env.GIT_REPO}"
            }
        }
        
        stage('Deploy to Remote Host') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'ssh-remote-server',
                                     usernameVariable: 'SSH_USER',
                                     passwordVariable: 'SSH_PASS'),
                    string(credentialsId: 'remote-host-ip', variable: 'HOST_IP'),
                    string(credentialsId: 'remote-path', variable: 'REMOTE_PATH')
                ]) {
                    script {
                        sh """
                            # Remote dizini oluştur
                            sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP '
                                mkdir -p \$REMOTE_PATH
                            '
                            
                            # docker-compose.yml dosyasını remote'a kopyala
                            sshpass -p \$SSH_PASS scp -o StrictHostKeyChecking=no ${COMPOSE_FILE} \$SSH_USER@\$HOST_IP:\$REMOTE_PATH/
                            
                            # Remote host üzerinde deploy
                            sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP '
                                cd \$REMOTE_PATH
                                docker-compose pull
                                docker-compose up -d
                            '
                        """
                    }
                }
            }
        }
    }
    
    post {
        success { echo "✅ Deployment completed successfully!" }
        failure { echo "❌ Deployment failed!" }
    }
}
