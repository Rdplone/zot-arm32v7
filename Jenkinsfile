pipeline {
    agent any
    
    environment {
        REMOTE_HOST = "$REMOTE_HOST"       // Remote server IP
        REMOTE_PATH = "$REMOTE_PATH"          // Hedef dizin
    }
    
    stages {
        stage('🔗 Test SSH Connection') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \
                        \$SSH_USER@\$REMOTE_HOST \
                        'echo "SSH connection successful - Current directory: \$(pwd)"'
                    """
                }
            }
        }
        
        stage('📁 Create Directory') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \
                        \$SSH_USER@\$REMOTE_HOST \
                        'mkdir -p \$REMOTE_PATH && echo "Directory created: \$REMOTE_PATH"'
                    """
                }
            }
        }
        
        stage('📝 Create Test File') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \
                        \$SSH_USER@\$REMOTE_HOST '
                            cd \$REMOTE_PATH
                            echo "Jenkins deployment test" > test-file.txt
                            echo "Created at: \$(date)" >> test-file.txt
                            echo "Build number: ${BUILD_NUMBER}" >> test-file.txt
                            
                            echo "File created successfully:"
                            cat test-file.txt
                        '
                    """
                }
            }
        }
        
        stage('✅ Verify Results') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'remote-server-ssh-pass',
                                                 usernameVariable: 'SSH_USER',
                                                 passwordVariable: 'SSH_PASS')]) {
                    sh """
                        sshpass -p \$SSH_PASS ssh -o StrictHostKeyChecking=no \
                        \$SSH_USER@\$REMOTE_HOST '
                            cd \$REMOTE_PATH
                            
                            echo "Directory contents:"
                            ls -la
                            
                            echo ""
                            echo "File content:"
                            cat test-file.txt
                        '
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ SSH connection and file creation successful!"
        }
        failure {
            echo "❌ Something went wrong!"
        }
    }
}
