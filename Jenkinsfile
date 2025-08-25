pipeline {
    agent any

    environment {
        REMOTE_HOST = "$REMOTE_HOST"      // Sunucu IP veya domain
        REMOTE_PATH = "$REMOTE_PATH"      // docker-compose.yml dizini
        DOCKER_IMAGE = "rdplone/zot-arm32v7:latest"  // Çekilecek image
    }

    stages {
        stage('Deploy with Docker Compose') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
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
