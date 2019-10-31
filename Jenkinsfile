import org.jenkinsci.plugins.pipeline.modeldefinition.Utils
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

@Library('jenkins-shared-libraries') _

def DEPLOY = params.getOrDefault("DEPLOY", false)
// tag as SNAPSHOT if not `master` or is `pr`
def SNAPSHOT =  DEPLOY ? true : (env.CHANGE_ID || env.BRANCH_NAME != 'master');
def TIMESTAMP = (new Date()).format("yyyyddMMHHmmss")
def APPROVED = false

// This looks like shit because of
//  - https://issues.jenkins-ci.org/browse/JENKINS-35988
//  - https://issues.jenkins-ci.org/browse/JENKINS-36195

pipeline {
    agent none
    parameters {
        booleanParam defaultValue: false, description: 'Deploy tagged images to docker hub.', name: 'DEPLOY'
    }
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '50', daysToKeepStr: '', numToKeepStr: '1000')
        timeout(time: 2, unit: 'HOURS')
        disableResume()
        durabilityHint 'PERFORMANCE_OPTIMIZED'
        disableConcurrentBuilds()
        skipStagesAfterUnstable()
    }
    environment {
        TIMESTAMP = "$TIMESTAMP"
    }
    stages {
        stage('Approve') {
            steps {
                script {
                    try
                    {
                        // don't allow skipping for master branch.
                        if (BRANCH_NAME.equals('master'))
                        {
                            APPROVED = true
                        }
                        else
                        {
                            timeout(time: 30, unit: "MINUTES") {
                                input(
                                    message: 'Approve this build? (please notify us in the #community channel to approve)',
                                    submitter: 'administrators,strongbox-core,strongbox-pro,strongbox-oss'
                                )
                                // retardness - if you "abort" the input, it will throw an exception,
                                // however if you "approve" it returns "null"!? This "fixes" it.
                                APPROVED = true
                            }
                        }
                    }
                    catch (FlowInterruptedException e)
                    {
                        println "Skipping build"
                        APPROVED = false
                        currentBuild.result = "NOT_BUILT"
                    }
                }
            }
        }
        stage('Build & Publish') {
            when {
                expression { APPROVED == true }
            }
            steps {
                script {
                    def buildStages = [:]
                    buildStages.put("alpine", distributionBuildStages("alpine", BRANCH_NAME, DEPLOY, SNAPSHOT))
                    buildStages.put("debian", distributionBuildStages("debian", BRANCH_NAME, DEPLOY, SNAPSHOT))
                    buildStages.put("centos", distributionBuildStages("centos", BRANCH_NAME, DEPLOY, SNAPSHOT))
                    buildStages.put("opensuse", distributionBuildStages("opensuse", BRANCH_NAME, DEPLOY, SNAPSHOT))
                    buildStages.put("ubuntu", distributionBuildStages("ubuntu", BRANCH_NAME, DEPLOY, SNAPSHOT))
                    parallel buildStages
                }
            }
        }
    }
}

def distributionBuildStages(DISTRIBUTION, BRANCH_NAME, DEPLOY, SNAPSHOT) {
    return {
        node('alpine-docker')
        {
            def IMAGES = []
            stage(DISTRIBUTION) {
                try {
                    stage('node') {
                        container("docker") {
                            nodeInfo("docker")
                            checkout scm
                        }
                    }
                    stage('base') {
                        container("docker") {
                            script {
                                def built = processDockerfiles(findDockerfiles((String) "./images/$DISTRIBUTION/Dockerfile.$DISTRIBUTION*"), SNAPSHOT);
                                IMAGES = IMAGES + built
                            }
                        }
                    }
                    stage('jdk8') {
                        container("docker") {
                            script {
                                def built = processDockerfiles(findDockerfiles((String) "./images/$DISTRIBUTION/jdk8"), SNAPSHOT);
                                IMAGES = IMAGES + built
                            }
                        }
                    }
                    stage('jdk11') {
                        container("docker") {
                            script {
                                def built = processDockerfiles(findDockerfiles((String) "./images/$DISTRIBUTION/jdk11"), SNAPSHOT);
                                IMAGES = IMAGES + built
                            }
                        }
                    }
                    stage('publish') {
                        if(BRANCH_NAME != "master" && DEPLOY != true) {
                            Utils.markStageSkippedForConditional(STAGE_NAME)
                            return;
                        }
                        container("docker") {
                            script {
                                echo "Images to push: " + IMAGES.toString()
                                withDockerRegistry([credentialsId: '6fedbf52-4df3-4328-90d6-0caf08edb68d', url: "https://index.docker.io/v1/"]) {
                                    def attempt = 0
                                    retry(5) {
                                        // wait for a moment, might be a temporary network issue?
                                        if(attempt > 0) {
                                            sleep 15
                                        }
                                        attempt++;
                                        IMAGES.each {
                                            sh label: "Publishing ${it}...",
                                               script: "docker push ${it}"
                                        }
                                    }
                                }
                            }
                        }
                    }
                } finally {
                    archiveArtifacts '**/*.build.log'
                }
            }
        }
    }
}

def findDockerfiles(path, maxDepth = "")
{
    def findArgs = maxDepth ? " -maxdepth $maxDepth " : ""
    // !!!!!!!! DO NOT MESS WITH THE QUOTES OR YOU WILL REGRET IT !!!!!!!!
    // https://gist.github.com/Faheetah/e11bd0315c34ed32e681616e41279ef4
    return sh(script: """find $path $findArgs -type f -name "*Dockerfile*" ! -name "*build.log" | sort | xargs""", label: "Searching for Dockerfiles", returnStdout: true)
}

def processDockerfiles(files, snapshot)
{
    def BUILD_ARGS = snapshot ? " --snapshot " : ""
    def images = [];

    files.split(" ").each {
        def match = (it =~ /(.*)\\/Dockerfile\.(\w+)(\.(.+))?/)
        if (match.find())
        {
            def attempt = 0
            retry(3) {
                // wait for a moment, might be a temporary network issue?
                if(attempt > 0) {
                    sleep 15
                }
                attempt++;

                // Do not use `docker.build` because it fails with `"docker build" requires exactly 1 argument.`.
                // docker.build(IMAGE, '-f ${it} --no-cache .')

                def IMAGE_TAG = sh(label: "Getting image tag", script: "/bin/bash ./build.sh ${BUILD_ARGS} --get-image $it", returnStdout: true)

                sh label: "Building $IMAGE_TAG",
                   script: "/bin/bash ./build.sh --no-cache ${BUILD_ARGS} $it"

                images.add(IMAGE_TAG)
            }
        }
        else
        {
            println "Something went wrong and we could not properly parse ${it} - skipping"
        }
    }

    return images
}
