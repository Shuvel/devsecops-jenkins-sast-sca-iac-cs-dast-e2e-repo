pipeline {
  agent any

  tools {
    maven 'Maven_3_8_7'   // ensure this tool name exists in Global Tool Config
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

    stage('Build') {
      steps {
        script {
          // If you’ve configured DockerHub creds in Jenkins, keep this as-is
          withDockerRegistry([credentialsId: "dockerlogin", url: ""]) {
            app = docker.build("asecurityguru/testeb")
          }
        }
      }
    }

    stage('RunContainerScan') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          sh '''
            # Snyk respects SNYK_TOKEN env; no need to print it
            export SNYK_TOKEN="$SNYK_TOKEN"
            # Optional: snyk auth "$SNYK_TOKEN"
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
          # Adjust the ZAP path if installed elsewhere
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
}

