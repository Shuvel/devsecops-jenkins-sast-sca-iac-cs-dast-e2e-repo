pipeline {
  agent any

  environment {
    // Helpful on Apple Silicon when building x86 images; remove if you want native arm64
    DOCKER_DEFAULT_PLATFORM = "linux/amd64"
  }

  tools {
    maven 'Maven_3_8_7'
    // jdk 'JDK11' // optional: pin JDK if you’ve configured it
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
        // Ensure Jenkins sees Docker from /opt/homebrew/bin
        withEnv(['PATH+DOCKER=/opt/homebrew/bin']) {
          sh '''
            echo "PATH=$PATH"
            command -v docker || true
            /opt/homebrew/bin/docker version
            /opt/homebrew/bin/docker info
          '''
        }
      }
    }

    stage('Build') {
      steps {
        script {
          // Append only /opt/homebrew/bin so the plugin finds docker
          withEnv(['PATH+DOCKER=/opt/homebrew/bin']) {
            sh '/opt/homebrew/bin/docker version' // quick sanity check in this stage
            withDockerRegistry([credentialsId: "dockerlogin", url: ""]) {
              // Build from workspace root; DOCKER_DEFAULT_PLATFORM controls arch
              app = docker.build("asecurityguru/testeb", ".")
            }
          }
        }
      }
    }

    stage('RunContainerScan') {
      steps {
        // Snyk uses the docker CLI to inspect the local image
        withEnv(['PATH+DOCKER=/opt/homebrew/bin']) {
          withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
            sh '''
              export SNYK_TOKEN="$SNYK_TOKEN"
              /opt/homebrew/bin/docker images | head -n 5
              snyk container test asecurityguru/testeb || true
            '''
          }
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
