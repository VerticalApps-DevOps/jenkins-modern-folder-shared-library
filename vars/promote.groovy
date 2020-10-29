def call() {
    withEnv(['url=ec2-54-164-120-194.compute-1.amazonaws.com', 
    'nexusUrl=http://ec2-54-234-181-83.compute-1.amazonaws.com:8081/repository/processes-verticalapps']) {
        withCredentials([usernamePassword( credentialsId: 'MFOrchestrator', 
                        usernameVariable: 'user', passwordVariable: 'pwd' )]) {

            def psscript = libraryResource 'promote.ps1'

            psCall = pwsh returnStdout: true, script: psscript 
            println psCall           
        }
    }
}
