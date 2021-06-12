def call(String tenant, String folderName) {
    withEnv(['url=https://devrpa.verticalapps.com', 'tenancy='+tenant, 'folderName='+folderName]) {
        withCredentials([usernamePassword( credentialsId: 'MFOrchestrator', 
                        usernameVariable: 'user', passwordVariable: 'pwd' )]) {

            def psscript = libraryResource 'auth.ps1'

            psCall = pwsh returnStdout: true, script: psscript 
            withEnv(['token=pscall']) {
                def publishscript = libraryResource 'publish.ps1'

                publishCall = pwsh returnStdout: true, script: publishscript 
            }
            println psCall           
        }
    }
}