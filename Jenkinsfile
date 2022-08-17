pipeline {
    agent any
    options { skipDefaultCheckout() }
    stages {
        stage("Checkout") {
            agent any
            options { skipDefaultCheckout() }
            when {
                allOf {
                    triggeredBy cause: 'UserIdCause'
                }
            }
            stages {
                stage('Build') {
                    steps {
                        checkout scm  
                        powershell '''
                            $oci_config = [IO.File]::ReadAllText("$env:USERPROFILE\\.oci\\config")
                            $oci_api_key_public = [IO.File]::ReadAllText("$env:USERPROFILE\\.oci\\oci_api_key_public.pem")
                            $oci_api_key = [IO.File]::ReadAllText("$env:USERPROFILE\\.oci\\oci_api_key.pem")
                            docker-compose build --build-arg OCI_CONFIG="$oci_config" --build-arg OCI_API_KEY_PUBLIC="$oci_api_key_public" --build-arg OCI_API_KEY="$oci_api_key" geoslicerbase-dev
                        '''
                    }
                }
                stage('Pack') {
                    steps {
                        powershell '''
                            $ls_remote_result = git ls-remote git@bitbucket.org:ltrace/slicer.git master
                            $slicer_repo_commit_tag = ($ls_remote_result -split '\\s+')[0]
                            docker-compose up -d --build geoslicerbase-dev
                            docker-compose exec geoslicerbase-dev python ./tools/update_cmakelists_content.py --commit "$slicer_repo_commit_tag"
                            docker-compose exec geoslicerbase-dev python ./tools/build_and_pack.py --source . --jobs 42 --type Release"
                        '''
                    }
                    post {
                        always {
                            powershell "docker-compose down"
                        }
                    }
                }
            }
        }
    }
}

