pipeline {
    agent any

    environment {
        REMOTE_PATH = credentials('REMOTE_PATH')   // Jenkins Credentials üzerinden
        REMOTE_HOST = credentials('REMOTE_HOST')   // Jenkins Credentials üzerinden
    }

    stages {
        stage('Deploy with Docker Compose') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'SSH_CREDENTIALS_ID',
                                                 keyFileVariable: 'SSH_KEY',
                                                 usernameVariable: 'SSH_USER')]) {
                    sh """
                        ssh -i $SSH_KEY -o StrictHostKeyChecking=no $SSH_USER@$REMOTE_HOST '
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
