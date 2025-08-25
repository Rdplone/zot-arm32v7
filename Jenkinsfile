pipeline {
    agent any

    environment {
        REMOTE_HOST = "$REMOTE_HOST"      // Remote server IP / hostname
        REMOTE_PATH = "$REMOTE_PATH"      // Remote server dizini
        DOCKER_IMAGE = "rdplone/zot-arm32v7:latest"  // Docker Hub imajı
    }

    stages {
        stage('Checkout docker-compose.yml') {
            steps {
                // Sadece docker-compose.yml çekiyoruz
                git branch: 'main',
                    url: 'https://github.com/Rdplone/zot-arm32v7.git',
                    changelog: false,
                    poll: false
            }
        }

        stage('Deploy to Remote Host') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_HOST '
                            mkdir -p $REMOTE_PATH
                        '
                        
                        # docker-compose.yml dosyasını remote host'a gönder
                        sshpass -p $SSH_PASS scp docker-compose.yml $SSH_USER@$REMOTE_HOST:$REMOTE_PATH/docker-compose.yml
                        
                        # Remote host üzerinde deploy
                        sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_HOST '
                            cd $REMOTE_PATH &&
                            sed -i "s|image:.*|image: $DOCKER_IMAGE|" docker-compose.yml &&
                            docker-compose pull &&
                            docker-compose up -d
                        '
                    """
                }
            }
        }
    }
}
