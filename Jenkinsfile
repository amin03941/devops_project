pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timeout(time: 40, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    environment {
        MAVEN_OPTS = '-Xmx512m'
    }

    stages {
        stage('Verifier les outils') {
            steps {
                sh 'java -version'
                sh 'mvn -version'
                sh 'docker version'
            }
        }

        stage('Construire Spring') {
            steps {
                dir('backend') {
                    sh 'mvn -B -DargLine="-Xmx384m" clean package'
                }
            }
        }

        stage('Analyser avec SonarQube') {
            steps {
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        withCredentials([string(
                            credentialsId: 'sonarqube-token',
                            variable: 'SONAR_TOKEN'
                        )]) {
                            sh '''
                                set +x
                                export SONAR_SCANNER_JAVA_OPTS="-Xmx512m"
                                mvn -B org.sonarsource.scanner.maven:sonar-maven-plugin:5.5.0.6356:sonar                                   -Dsonar.projectKey=devops-gestion-projets                                   -Dsonar.host.url="$SONAR_HOST_URL"                                   -Dsonar.scanner.skipJreProvisioning=true -Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=300
                            '''
                        }
                    }
                }
            }
        }

        stage('Construire Angular') {
            steps {
                dir('frontend') {
                    sh '''
                        docker run --rm \
                          --user "$(id -u):$(id -g)" \
                          -e HOME=/tmp \
                          -e CI=true \
                          -e NG_CLI_ANALYTICS=false \
                          -e NG_BUILD_MAX_WORKERS=2 \
                          -e NODE_OPTIONS=--max-old-space-size=1024 \
                          -v "$PWD:/app" \
                          -w /app \
                          node:24-bookworm-slim \
                          sh -c 'npm ci --maxsockets=3 --fetch-retries=5 --fetch-timeout=600000 --no-audit --no-fund && npm run build -- --output-path=dist/frontend'
                    '''
                }
            }
        }

        stage('Construire les images Docker') {
            steps {
                sh 'docker build -t gestion-backend:ci-$BUILD_NUMBER backend'
                sh 'docker build -t gestion-frontend:ci-$BUILD_NUMBER frontend'
            }
        }

        stage('Publier sur Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_TOKEN'
                )]) {
                    sh '''
                        set +x
                        set -eu
                        export DOCKER_CONFIG="$(mktemp -d)"
                        trap 'rm -rf "$DOCKER_CONFIG"' EXIT

                        printf '%s' "$DOCKER_TOKEN" | docker login                           --username "$DOCKER_USER" --password-stdin

                        for component in backend frontend; do
                            source="gestion-${component}:ci-${BUILD_NUMBER}"
                            target="mohamedaminkharrat/gestion-${component}"

                            docker tag "$source" "$target:ci-${BUILD_NUMBER}"
                            docker tag "$source" "$target:latest"

                            docker push "$target:ci-${BUILD_NUMBER}"
                            docker push "$target:latest"
                        done
                    '''
                }
            }
        }
    }

    post {
        always {
            junit testResults: 'backend/target/surefire-reports/TEST-*.xml',
                  allowEmptyResults: false
        }
        success {
            archiveArtifacts artifacts: 'backend/target/*.jar',
                             fingerprint: true
        }
    }
}
