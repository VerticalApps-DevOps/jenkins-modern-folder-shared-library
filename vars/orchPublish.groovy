def call(String tenant, String folderName) {
   withEnv(['url=https://rpa-dev.uscis.dhs.gov/', 'tenancy='+tenant, 'folderName='+folderName]) {
        withCredentials([usernamePassword( credentialsId: 'jenkins-user-rpa', 
                        usernameVariable: 'user', passwordVariable: 'pwd' )]) {

            def psscript = libraryResource 'orchPublish.ps1'

            psCall = pwsh returnStdout: true, script: psscript 
            println psCall           
        }
    }
}
