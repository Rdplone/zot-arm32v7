pipeline {
    agent any

    environment {
        COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('Deploy to Remote Host') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'ssh-remote-server',
                                     usernameVariable: 'SSH_USER',
                                     passwordVariable: 'SSH_PASS'),
                    string(credentialsId: 'remote-host-ip', variable: 'HOST_IP'),
                    string(credentialsId: 'remote-path', variable: 'REMOTE_PATH')
                ]) {
                    sh """
                        echo ">>> 🚀 Deploy başlıyor..."
                        echo "Remote host: \$HOST_IP"
                        echo "Remote path: \$REMOTE_PATH"
                        pwd
                        ls

                        # Remote dizini oluştur
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP "mkdir -p \$REMOTE_PATH"

                        # docker-compose.yml dosyasını kopyala
                        sshpass -p \$SSH_PASS scp -o StrictHostKeyChecking=no \$COMPOSE_FILE \$SSH_USER@\$HOST_IP:\$REMOTE_PATH/

                        # Remote host üzerinde deploy
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP "
                            cd \$REMOTE_PATH
                            docker-compose pull
                            docker-compose up -d
                        "
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment başarılı!"
        }
        failure {
            echo "❌ Deployment başarısız!"
        }
    }
}
