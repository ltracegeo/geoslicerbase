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
                                    // $oci_config = [IO.File]::ReadAllText("$env:USERPROFILE\\.oci\\config")
                                    // $oci_api_key_public = [IO.File]::ReadAllText("$env:USERPROFILE\\.oci\\oci_api_key_public.pem")
                                    // $oci_api_key = [IO.File]::ReadAllText("$env:USERPROFILE\\.oci\\oci_api_key.pem")
                                powershell '''
                                    docker-compose build geoslicerbase-windows-dev
                                '''
                            }
                            post {
                                always {
                                    powershell "docker image prune -f"
                                }
                            }
                        }
                        stage('Build & Pack [Windows]') {
                            options {
                                timeout(time: 15, unit: "HOURS")
                            }
                            steps {                        
                                // Check git tag related to current branch
                                // script {
                                //     env.GIT_LS_REMOTE_RESULT = powershell(returnStdout: true, script: 'git ls-remote git@bitbucket.org:ltrace/slicer.git ${env:SLICER_BRANCH}').trim()                            
                                //     env.SLICER_GIT_COMMIT = powershell(returnStdout: true, script: '(${env:GIT_LS_REMOTE_RESULT} -split "\\s+")[0]').trim()
                                // }
                                powershell '''
                                    docker-compose up -d geoslicerbase-windows-dev --wait
                                    docker-compose exec -T geoslicerbase-windows-dev python ./geoslicerbase/tools/update_cmakelists_content.py --commit "${env:SLICER_BRANCH}"
                                    docker-compose exec -T geoslicerbase-windows-dev python ./geoslicerbase/tools/build_and_pack.py --source ./geoslicerbase --avoid-long-path --jobs "${env:THREADS}" --type "${env:BUILD_TYPE}"
                                '''
                            }
                            post {
                                always {
                                    powershell "docker-compose down --remove-orphans -v"
                                    powershell "docker system prune --force --filter 'until=3h'"
                                    powershell "docker volume prune --force"
                                    archiveArtifacts artifacts: 'tools/docker/*.log', fingerprint: true, allowEmptyArchive: true
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
                                sh '''
                                    docker-compose build geoslicerbase-linux
                                   '''
                                    // oci_config="$(cat ${HOME}/.oci/config)"
                                    // oci_api_key_public="$(cat ${HOME}/.oci/oci_api_key_public.pem)"
                                    // oci_api_key="$(cat ${HOME}/.oci/oci_api_key.pem)"
                                    // docker-compose build geoslicerbase-linux
                            }
                            post {
                                always {
                                    sh "docker image prune -f"
                                }
                            }
                        }
                        stage('Build & Pack [Linux]') {
                            options {
                                timeout(time: 15, unit: "HOURS")
                            }
                            steps {                        
                                // Check git tag related to current branch
                                // script {
                                //     env.SLICER_GIT_COMMIT = sh(returnStdout: true, script: "echo \$(git ls-remote git@bitbucket.org:ltrace/slicer.git \${SLICER_BRANCH}) | awk '{print \$1}'").trim()
                                // }
                                sh '''
                                    docker-compose up -d geoslicerbase-linux --wait
                                    docker-compose exec -T geoslicerbase-linux python /geoslicerbase/tools/update_cmakelists_content.py --commit "${SLICER_BRANCH}"
                                    docker-compose exec -T geoslicerbase-linux python /geoslicerbase/tools/build_and_pack.py --source /geoslicerbase --avoid-long-path --jobs "${THREADS}" --type "${BUILD_TYPE}"
                                '''
                                // docker-compose exec -T geoslicerbase-linux python /geoslicerbase/tools/update_cmakelists_content.py --commit 9e2b29a
                                // docker-compose exec -T geoslicerbase-linux python /geoslicerbase/tools/build_and_pack.py --source ./geoslicerbase --avoid-long-path --jobs "8" --type "Release"
                            }
                            post {
                                always {
                                    sh "docker-compose down --remove-orphans -v"
                                    sh "docker system prune --force --filter 'until=3h'"
                                    sh "docker volume prune --force"
                                    archiveArtifacts artifacts: 'tools/docker/*.log', fingerprint: true, allowEmptyArchive: true
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

