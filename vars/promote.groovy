def call() {
    withEnv(['url=https://devrpa.verticalapps.com', 
    'nexusUrl=http://ec2-54-196-97-102.compute-1.amazonaws.com:8081/repository/processes-verticalapps']) {
        withCredentials([usernamePassword( credentialsId: 'MFOrchestrator', 
                        usernameVariable: 'user', passwordVariable: 'pwd' )]) {

            def psscript = libraryResource 'promote.ps1'

            psCall = pwsh returnStdout: true, script: psscript 
            println psCall           
        }
    }
}