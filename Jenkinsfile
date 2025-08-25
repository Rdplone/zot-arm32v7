pipeline {
    agent any
    
    environment {
        GIT_REPO = "https://github.com/Rdplone/zot-arm32v7.git"
        COMPOSE_FILE = "docker-compose.yml"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${env.GIT_REPO}"
            }
        }
        
        stage('Deploy to Remote Host') {
            steps {
                // SSH_USER + SSH_PASS ve REMOTE_PATH + HOST_IP credentialları
                withCredentials([
                    usernamePassword(credentialsId: 'ssh-remote-server',
                                     usernameVariable: 'SSH_USER',
                                     passwordVariable: 'SSH_PASS'),
                    string(credentialsId: 'remote-host-ip', variable: 'HOST_IP'),
                    string(credentialsId: 'remote-path', variable: 'REMOTE_PATH')
                ]) {
                    script {
                        // Remote dizini oluştur (varsa değiştirmez)
                        sh """
                            sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP '
                                mkdir -p \$REMOTE_PATH
                            '
                            
                            # GitHub'dan çekilen docker-compose.yml dosyasını remote'a kopyala
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
