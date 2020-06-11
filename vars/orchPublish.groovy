def call(String tenant, long folderId, long environmentId) {
    withEnv(['url=https://devrpa.verticalapps.com', 'tenancy='+tenant, 'folderId='+folderId, 'environmentId='+environmentId]) {
        withCredentials([usernamePassword( credentialsId: 'MFOrchestrator', 
                        usernameVariable: 'user', passwordVariable: 'pwd' )]) {

            def psscript = libraryResource 'orchPublish.ps1'

            psCall = pwsh returnStdout: true, script: psscript 
            println psCall           
        }
    }
}