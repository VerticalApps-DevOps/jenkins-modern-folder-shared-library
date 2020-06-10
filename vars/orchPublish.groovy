def call(String tenant, long, folderId, long environmentId) {
    withEnv(['url=https://uipath.verticalapps.com', 'tenancy='+tenant, 'folderId='+folderId, 'environmentId='+environmentId]) {
        withCredentials([usernamePassword( credentialsId: 'orchestrator-authentication', 
                        usernameVariable: 'user', passwordVariable: 'pwd' )]) {

            def psscript = libraryResource 'orchPublish.ps1'

            psCall = pwsh returnStdout: true, script: psscript 
            println psCall           
        }
    }
}