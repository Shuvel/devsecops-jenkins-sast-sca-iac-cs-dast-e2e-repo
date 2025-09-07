pipeline {
  agent any

  environment {
    // Make docker + system tools visible to ALL steps
    PATH = "/opt/homebrew/bin:/usr/local/bin:/bin:/usr/bin:${env.PATH}"
    // Keep if you need x86 images on Apple Silicon; remove for native arm64
    DOCKER_DEFAULT_PLATFORM = "linux/amd64"
    IMAGE = "asecurityguru/testeb"
  }

  tools {
    maven 'Maven_3_8_7'
    // jdk 'JDK11' // optional if pinned in Jenkins
  }

  stages {

    stage('Check Shell & Docker') {
      steps {
        sh '''
          set -e
          echo "PATH=$PATH"
          echo -n "shell executable: "; ps -p $$ -o comm=
          command -v docker
          docker version
          docker info || true
        '''
      }
    }

    stage('CompileandRunSonarAnalysis') {
      steps {
        withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
          sh '''
            set -e
            mvn -Dmaven.test.failure.ignore verify sonar:sonar \
              -Dsonar.token=$SONAR_TOKEN \
              -Dsonar.projectKey=easybuggy \
              -Dsonar.host.url=http://localhost:9000/
          '''
        }
      }
    }

    stage('Build') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerlogin', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            set -euo pipefail
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker version
            # Build image (DOCKER_DEFAULT_PLATFORM controls arch)
            docker build -t "$IMAGE" .
            # docker push "$IMAGE"   # uncomment when you want to push
            docker logout || true
          '''
        }
      }
    }

    stage('RunContainerScan') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          sh '''
            set -e
            export SNYK_TOKEN="$SNYK_TOKEN"
            docker images | head -n 5 || true
            snyk container test "$IMAGE" || true
          '''
        }
      }
    }

    stage('RunSnykSCA') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          sh '''
            set -e
            export SNYK_TOKEN="$SNYK_TOKEN"
            mvn -B snyk:test -fn
          '''
        }
      }
    }

    stage('RunDASTUsingZAP') {
      steps {
        sh '''
          set -e
          if [ -x "/Users/jrschavel/Documents/GitHub/Tools/ZAP_2.16.1/zap.sh" ]; then
            "/Users/jrschavel/Documents/GitHub/Tools/ZAP_2.16.1/zap.sh" \
              -port 9393 -cmd \
              -quickurl https://www.example.com \
              -quickprogress \
              -quickout /tmp/zap-output.html
          else
            echo "ZAP not found at given path; skipping DAST"
          fi
        '''
      }
    }

    stage('checkov') {
      steps {
        sh '''
          set -euo pipefail
          if command -v checkov >/dev/null 2>&1; then
            echo "Running local Checkov"
            checkov -s -f main.tf
          else
            echo "Checkov CLI not found; using Docker image"
            test -n "$(command -v docker)" || { echo "docker not found"; exit 1; }
            docker run --rm -v "$PWD":/src bridgecrew/checkov -s -f /src/main.tf
          fi
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
