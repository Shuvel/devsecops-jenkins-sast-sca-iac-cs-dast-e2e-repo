pipeline {
  agent any

  environment {
    // Make docker visible to all steps (including plugin login/logout cleanup)
    PATH = "/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
    // On Apple Silicon, keep this if you build x86 images; remove for native arm64
    DOCKER_DEFAULT_PLATFORM = "linux/amd64"
  }

  tools {
    maven 'Maven_3_8_7'
    // jdk 'JDK11' // optional if you pinned a JDK in Jenkins
  }

  stages {
    stage('CompileandRunSonarAnalysis') {
      steps {
        withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
          sh '''
            mvn -Dmaven.test.failure.ignore verify sonar:sonar \
              -Dsonar.token=$SONAR_TOKEN \
              -Dsonar.projectKey=easybuggy \
              -Dsonar.host.url=http://localhost:9000/
          '''
        }
      }
    }

    stage('Check Docker') {
      steps {
        sh '''
          echo "PATH=$PATH"
          command -v docker
          docker version
          docker info
        '''
      }
    }

    stage('Build') {
      steps {
        script {
          withDockerRegistry([credentialsId: "dockerlogin", url: ""]) {
            sh 'docker version' // sanity check
            // Build from workspace root; DOCKER_DEFAULT_PLATFORM controls arch
            app = docker.build("asecurityguru/testeb", ".")
          }
        }
      }
    }

    stage('RunContainerScan') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          sh '''
            export SNYK_TOKEN="$SNYK_TOKEN"
            docker images | head -n 5
            snyk container test asecurityguru/testeb || true
          '''
        }
      }
    }

    stage('RunSnykSCA') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          sh '''
            export SNYK_TOKEN="$SNYK_TOKEN"
            mvn -B snyk:test -fn
          '''
        }
      }
    }

    stage('RunDASTUsingZAP') {
      steps {
        sh '''
          "/Users/jrschavel/Documents/GitHub/Tools/ZAP_2.16.1/zap.sh" \
            -port 9393 -cmd \
            -quickurl https://www.example.com \
            -quickprogress \
            -quickout /tmp/zap-output.html
        '''
      }
    }

    stage('checkov') {
      steps {
        sh '''
          # Ensure checkov is installed (e.g., pipx install checkov)
          checkov -s -f main.tf
        '''
      }
    }
  }

  post {
    always {
      // Archive ZAP report if present
      sh 'test -f /tmp/zap-output.html && echo "ZAP report found" || true'
      archiveArtifacts artifacts: '/tmp/zap-output.html', allowEmptyArchive: true
    }
  }
}
