pipeline {
    agent any
    
    environment {
        COMPOSE_FILE = 'docker-compose.yaml'
    }
    
    stages {
        stage('Deploy to Remote Host') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'ssh-remote-server', usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS'),
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
                        
                        # Eğer remote host'ta docker-compose.yaml varsa temizlik yap
                        echo ">>> 🧹 Mevcut deployment kontrolü ve temizlik..."
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP "
                            cd \$REMOTE_PATH
                            if [ -f docker-compose.yaml ]; then
                                echo 'Mevcut docker-compose.yaml bulundu, containers durduruluyor...'
                                docker compose down || true
                                echo 'Docker sistem temizliği yapılıyor...'
                                docker system prune -af --volumes || true
                                echo 'Eski docker-compose.yaml siliniyor...'
                                rm -f docker-compose.yaml
                                echo 'Temizlik tamamlandı.'
                            else
                                echo 'Mevcut docker-compose.yaml bulunamadı, temizlik atlanıyor.'
                            fi
                        "
                        
                        # Yeni docker-compose.yaml dosyasını kopyala
                        echo ">>> 📋 Yeni docker-compose.yaml kopyalanıyor..."
                        sshpass -p \$SSH_PASS scp -o StrictHostKeyChecking=no \$COMPOSE_FILE \$SSH_USER@\$HOST_IP:\$REMOTE_PATH/
                        
                        # Remote host üzerinde yeni deployment
                        echo ">>> 🚀 Yeni deployment başlatılıyor..."
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \$SSH_USER@\$HOST_IP "
                            cd \$REMOTE_PATH
                            docker compose pull
                            docker compose up -d
                        "
                        
                        echo ">>> ✅ Deploy işlemi tamamlandı!"
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
