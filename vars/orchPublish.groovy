def call(String tenant, String folderName, long environmentId) {
    withEnv(['url=https://devrpa.verticalapps.com', 'tenancy='+tenant, 'folderName='+folderName, 'environmentId='+environmentId]) {
        withCredentials([usernamePassword( credentialsId: 'MFOrchestrator', 
                        usernameVariable: 'user', passwordVariable: 'pwd' )]) {

            def psscript = libraryResource 'orchPublish.ps1'

            psCall = pwsh returnStdout: true, script: psscript 
            println psCall           
        }
    }
}