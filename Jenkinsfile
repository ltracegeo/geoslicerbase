pipeline {
    agent any
    options { skipDefaultCheckout() }
    parameters {
        string(name: 'SLICER_BRANCH', defaultValue: "main", description: 'The LTrace/Slicer.git branch to build')
        choice(name: 'PLATFORM', choices: ['Windows', 'Linux', 'Both'], description: 'Select the desired Operational System to generate the application.')
        choice(name: 'BUILD_TYPE', choices: ['Release', 'Debug'], description: 'Select the build type.')
        choice(name: 'THREADS', choices: ['32', '16', '8', '4', '2', '1'], description: 'Select the desired Operational System to generate the application.')
    }
    stages {
        stage("Parallel Stage") {
            options { skipDefaultCheckout() }
            when {
                allOf {
                    triggeredBy cause: 'UserIdCause'
                }
            }
            failFast true
            parallel {
                stage("Windows") {
                    agent {
                            label "windows"
                    }
                    options { skipDefaultCheckout() }
                    when { 
                        anyOf {
                                expression { return "${params.PLATFORM}" == "Windows"; } 
                                expression { return "${params.PLATFORM}" == "Both"; } 
                        }
                    }
                    stages {
                        stage('Build [Windows]') {
                            steps {
                                checkout scm  
                                powershell '''
                                    $oci_config = [IO.File]::ReadAllText("$env:USERPROFILE\\.oci\\config")
                                    $oci_api_key_public = [IO.File]::ReadAllText("$env:USERPROFILE\\.oci\\oci_api_key_public.pem")
                                    $oci_api_key = [IO.File]::ReadAllText("$env:USERPROFILE\\.oci\\oci_api_key.pem")
                                    docker-compose build --build-arg OCI_CONFIG="${oci_config}" --build-arg OCI_API_KEY_PUBLIC="${oci_api_key_public}" --build-arg OCI_API_KEY="${oci_api_key}" geoslicerbase-windows-dev
                                '''
                            }
                            post {
                                always {
                                    powershell "docker image prune -f"
                                }
                            }
                        }
                        stage('Pack [Windows]') {
                            steps {                        
                                // Check git tag related to current branch
                                script {
                                    env.GIT_LS_REMOTE_RESULT = powershell(returnStdout: true, script: 'git ls-remote git@bitbucket.org:ltrace/slicer.git ${env:SLICER_BRANCH}').trim()                            
                                    env.SLICER_GIT_COMMIT = powershell(returnStdout: true, script: '(${env:GIT_LS_REMOTE_RESULT} -split "\\s+")[0]').trim()
                                }
                                powershell '''
                                    docker-compose up -d geoslicerbase-windows-dev --wait
                                    docker-compose exec -T geoslicerbase-windows-dev python ./geoslicerbase/tools/update_cmakelists_content.py --commit "${env:SLICER_GIT_COMMIT}"
                                    docker-compose exec -T geoslicerbase-windows-dev python ./geoslicerbase/tools/build_and_pack.py --source ./geoslicerbase --jobs "${env:THREADS}" --type "${env:BUILD_TYPE}"
                                '''
                            }
                            post {
                                always {
                                    powershell "docker-compose down --remove-orphans -v"
                                }
                            }
                        }
                    }
                }
                stage("Linux") {
                    agent {
                            label "linux"
                    }
                    options { skipDefaultCheckout() }
                    when { 
                        anyOf {
                                expression { return "${params.PLATFORM}" == "Linux"; } 
                                expression { return "${params.PLATFORM}" == "Both"; } 
                        }
                    }
                    stages {
                        stage('Build [Linux]') {
                            steps {
                                checkout scm  
                                sh '''
                                    oci_config="$(cat ${HOME}/.oci/config)"
                                    oci_api_key_public="$(cat ${HOME}/.oci/oci_api_key_public.pem)"
                                    oci_api_key="$(cat ${HOME}/.oci/oci_api_key.pem)"
                                    docker compose build --build-arg OCI_CONFIG="${oci_config}" --build-arg OCI_API_KEY_PUBLIC="${oci_api_key_public}" --build-arg OCI_API_KEY="${oci_api_key}" geoslicerbase-ubuntu-dev
                                '''
                            }
                            post {
                                always {
                                    sh "docker image prune -f"
                                }
                            }
                        }
                        stage('Pack [Linux]') {
                            steps {                        
                                // Check git tag related to current branch
                                script {
                                    env.SLICER_GIT_COMMIT = sh(returnStdout: true, script: "echo \$(git ls-remote git@bitbucket.org:ltrace/slicer.git \${SLICER_BRANCH}) | awk '{print \$1}'").trim()
                                }
                                sh '''
                                    docker compose up -d geoslicerbase-ubuntu-dev --wait
                                    docker compose exec -T geoslicerbase-ubuntu-dev python ./geoslicerbase/tools/update_cmakelists_content.py --commit "${SLICER_GIT_COMMIT}"
                                    docker compose exec -T geoslicerbase-ubuntu-dev python ./geoslicerbase/tools/build_and_pack.py --source ./geoslicerbase --avoid-long-path --jobs "${THREADS}" --type "${BUILD_TYPE}"
                                '''
                            }
                            post {
                                always {
                                    sh "docker compose down --remove-orphans -v"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

