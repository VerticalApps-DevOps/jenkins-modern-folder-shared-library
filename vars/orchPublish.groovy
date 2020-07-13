def call(String tenant, String folderName) {
  withEnv(['url=https://devrpa.verticalapps.com', 'tenancy='+tenant, 'folderName='+folderName]) {
        withCredentials([usernamePassword( credentialsId: 'MFOrchestrator',
                        usernameVariable: 'user', passwordVariable: 'pwd' )]) {

            def psscript = libraryResource 'orchPublish.ps1'

            psCall = pwsh returnStdout: true, script: psscript 
            println psCall           
        }
    }
}
