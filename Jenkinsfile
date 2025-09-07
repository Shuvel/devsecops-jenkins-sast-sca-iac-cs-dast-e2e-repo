pipeline {
  agent any

  environment {
    // Make sure Jenkins can see Docker CLI on macOS
    PATH = "/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin:${env.PATH}"
    // If you’re on Apple Silicon but building x86 images, set default platform
    DOCKER_DEFAULT_PLATFORM = "linux/amd64"
  }

  tools {
    maven 'Maven_3_8_7'   // ensure this name exists in Global Tool Config
    // If you pinned a JDK in Jenkins, you can add: jdk 'JDK11'
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
      // Make sure the docker CLI is on PATH right here
      withEnv(['PATH+DOCKER=/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin']) {
        sh 'docker version'  // quick sanity check in this stage

        withDockerRegistry([credentialsId: "dockerlogin", url: ""]) {
          app = docker.build("asecurityguru/testeb", ".")
        }
      }
    }
  }
}

stage('RunContainerScan') {
  steps {
    withEnv(['PATH+DOCKER=/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin']) {
      withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
        sh '''
          export SNYK_TOKEN="$SNYK_TOKEN"
          docker images | head -n 5
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
          checkov -s -f main.tf
        '''
      }
    }
  }

  post {
    always {
      // Grab ZAP report if it exists
      sh 'test -f /tmp/zap-output.html && echo "ZAP report found" || true'
      archiveArtifacts artifacts: '/tmp/zap-output.html', allowEmptyArchive: true
    }
  }
}
