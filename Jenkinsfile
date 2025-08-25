pipeline {
    agent any

    environment {
        REMOTE_HOST = "$REMOTE_HOST"      // Remote server IP / hostname
        REMOTE_PATH = "$REMOTE_PATH"      // Remote server docker-compose.yml path
        DOCKER_IMAGE = "rdplone/zot-arm32v7:latest"  // Docker Hub imajı
    }

    stages {
        stage('Checkout Jenkinsfile & Compose') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/Rdplone/zot-arm32v7.git'
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_HOST '
                            mkdir -p $REMOTE_PATH &&
                            cat > $REMOTE_PATH/docker-compose.yml <<EOF
$(cat docker-compose.yml | sed "s|image:.*|image: $DOCKER_IMAGE|")
EOF
                            cd $REMOTE_PATH &&
                            docker-compose pull &&
                            docker-compose up -d
                        '
                    """
                }
            }
        }
    }
}
