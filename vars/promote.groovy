def call() {
    withEnv(['url=https://devrpa.verticalapps.com') {
        withCredentials([usernamePassword( credentialsId: 'MFOrchestrator', 
                        usernameVariable: 'user', passwordVariable: 'pwd' )]) {

            def psscript = libraryResource 'promote.ps1'

            psCall = pwsh returnStdout: true, script: psscript 
            println psCall           
        }
    }
}