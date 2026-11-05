pipeline {
    agent any
    tools { maven 'M3'; jdk 'JDK21' }
    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 40, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '10'))
    }
    triggers { githubPush() }
    environment {
        NEXUS_URL = 'http://nexus:8081'
        NEXUS_REPO = 'maven-snapshots'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'java -version && mvn -version'
            }
        }
        stage('Build') {
            steps { dir('sample-java-app') { sh 'mvn -B -ntp clean compile' } }
        }
        stage('Test') {
            steps { dir('sample-java-app') { sh 'mvn -B -ntp test' } }
            post {
                always {
                    junit testResults: 'sample-java-app/target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }
        stage('SonarQube Analysis') {
            steps {
                dir('sample-java-app') {
                    withSonarQubeEnv('SonarQube') {
                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                set +x
                                mvn -B -ntp sonar:sonar \
                                    -Dsonar.qualitygate.wait=true \
                                    -Dsonar.qualitygate.timeout=300
                            '''
                        }
                    }
                }
            }
        }
        stage('Package & Archive') {
            steps {
                dir('sample-java-app') {
                    sh 'mvn -B -ntp package -DskipTests'
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                    archiveArtifacts artifacts: 'target/site/jacoco/**', allowEmptyArchive: false
                }
            }
        }
        stage('Publish to Nexus') {
            steps {
                dir('sample-java-app') {
                    withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                        configFileProvider([configFile(fileId: 'maven-settings-nexus', variable: 'MAVEN_SETTINGS')]) {
                            sh '''
                                set +x
                                mvn -B -ntp deploy:deploy-file \
                                    -s "$MAVEN_SETTINGS" \
                                    -DpomFile=pom.xml \
                                    -Dfile=target/ci-demo-1.0.0-SNAPSHOT.jar \
                                    -Durl="$NEXUS_URL/repository/$NEXUS_REPO/" \
                                    -DrepositoryId=nexus
                            '''
                        }
                    }
                }
            }
        }
    }
    post {
        success { echo "CI SUCCESS: artifact published to ${env.NEXUS_URL}/repository/${env.NEXUS_REPO}/" }
        failure { echo 'CI FAILED: inspect Console Output; do not treat skipped stages as passed.' }
        always { cleanWs() }
    }
}
