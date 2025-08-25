pipeline {
    agent any

    environment {
        COMPOSE_FILE = 'docker-compose.yaml'
        GIT_REPO = 'https://github.com/Rdplone/zot-arm32v7'
        GIT_BRANCH = 'main'
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

                        # Remote dizini oluştur
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP "mkdir -p \$REMOTE_PATH"

                        # Eğer eski docker-compose.yaml varsa önce servisleri durdur ve temizle
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP "
                            cd \$REMOTE_PATH
                            if [ -f docker-compose.yaml ]; then
                                echo 'Eski docker-compose.yaml bulundu. Servisler durduruluyor...'
                                docker compose down || true

                                echo 'Docker objeleri temizleniyor...'
                                docker system prune -af --volumes || true

                                echo 'Eski docker-compose.yaml siliniyor...'
                                rm -f docker-compose.yaml
                            else
                                echo 'docker-compose.yaml bulunamadı. GitHub\'dan çekilecek.'
                            fi
                        "

                        # Eğer COMPOSE_FILE Jenkins workspace'te yoksa GitHub'dan indir
                        if [ ! -f \$COMPOSE_FILE ]; then
                            echo 'docker-compose.yaml Jenkins workspace\'te bulunamadı. GitHub\'dan indiriliyor...'
                            curl -fsSL \$GIT_REPO/raw/\$GIT_BRANCH/\$COMPOSE_FILE -o \$COMPOSE_FILE
                        fi

                        # Yeni docker-compose.yaml dosyasını kopyala
                        sshpass -p \$SSH_PASS scp -o StrictHostKeyChecking=no \$COMPOSE_FILE \$SSH_USER@\$HOST_IP:\$REMOTE_PATH/

                        # Remote host üzerinde deploy
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP "
                            cd \$REMOTE_PATH
                            docker compose pull
                            docker compose up -d
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
