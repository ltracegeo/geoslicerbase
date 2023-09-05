pipeline {
    agent any
    options { skipDefaultCheckout() }
    parameters {
        string(name: "TAG", defaultValue: "latest", description: "The GeoSlicer base version to add as a tag")
        choice(name: "PLATFORM", choices: ["Both", "Windows", "Linux"], description: "Select the desired Operational System to generate the application.")
    }
    environment {
        OCI_DOCKER_REGISTRY_TOKEN_ID     = credentials("oci_docker_registry_token_id")
        OCI_DOCKER_REGISTRY_TOKEN_PASSWORD = credentials("oci_docker_registry_token_password")
    }
    stages {
        stage("Parallel Stage") {
            options { skipDefaultCheckout() }
            when {
                allOf {
                    triggeredBy cause: 'UserIdCause'
                }
            }
            parallel {
                stage("Windows") {
                    options { skipDefaultCheckout() }
                    when {
                        beforeAgent true;
                        anyOf {
                                expression { return "${params.PLATFORM}" == "Windows"; } 
                                expression { return "${params.PLATFORM}" == "Both"; } 
                        }
                    }
                    agent {
                            label "windows"
                    }
                    stages {
                        stage('Build Image [Windows]') {
                            options {
                                timeout(time: 120, unit: "MINUTES")
                            }
                            steps {
                                cleanWs()
                                checkout scm  
                                powershell 'docker-compose build geoslicerbase-windows'
                                powershell 'docker login gru.ocir.io -u "$env:OCI_DOCKER_REGISTRY_TOKEN_ID" -p "$env:OCI_DOCKER_REGISTRY_TOKEN_PASSWORD"'
                                powershell 'docker tag geoslicerbase-windows gru.ocir.io/grrjnyzvhu1t/geoslicer/windows:$env:TAG'
                                powershell 'docker push gru.ocir.io/grrjnyzvhu1t/geoslicer/windows:$env:TAG'
                            }
                            post {
                                always {
                                    powershell "docker system prune --force --filter 'until=3h'"
                                    powershell "docker volume prune --force"
                                }
                            }
                        }
                    }
                    post {
                        // Clean after build
                        always {
                            cleanWs(cleanWhenNotBuilt: false,
                                    deleteDirs: true,
                                    disableDeferredWipeout: true,
                                    notFailBuild: true,
                                    patterns: [[pattern: '.gitignore', type: 'INCLUDE'],
                                            [pattern: '.propsfile', type: 'EXCLUDE']])
                        }
                    }
                }
                stage("Linux") {
                    options { skipDefaultCheckout() }
                    when {
                        beforeAgent true;
                        anyOf {
                                expression { return "${params.PLATFORM}" == "Linux"; } 
                                expression { return "${params.PLATFORM}" == "Both"; } 
                        }
                    }
                    agent {
                            label "linux"
                    }
                    stages {
                        stage('Build Image [Linux]') {
                            options {
                                timeout(time: 120, unit: "MINUTES")
                            }
                            steps {
                                cleanWs()
                                checkout scm  
                                sh 'docker-compose build geoslicerbase-linux'
                                sh 'docker login gru.ocir.io -u "$OCI_DOCKER_REGISTRY_TOKEN_ID" -p "$OCI_DOCKER_REGISTRY_TOKEN_PASSWORD"'
                                sh 'docker tag geoslicerbase-linux gru.ocir.io/grrjnyzvhu1t/geoslicer/linux:$TAG'
                                sh 'docker push gru.ocir.io/grrjnyzvhu1t/geoslicer/linux:$TAG'
                            }
                            post {
                                always {
                                    sh "docker system prune --force --filter 'until=3h'"
                                    sh "docker volume prune --force"
                                }
                            }
                        }
                    }
                    post {
                        // Clean after build
                        always {
                            cleanWs(cleanWhenNotBuilt: false,
                                    deleteDirs: true,
                                    disableDeferredWipeout: true,
                                    notFailBuild: true,
                                    patterns: [[pattern: '.gitignore', type: 'INCLUDE'],
                                            [pattern: '.propsfile', type: 'EXCLUDE']])
                        }
                    }
                }
            }
        }
    }
}

