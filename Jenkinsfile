#!/usr/bin/env groovy

/* IMPORTANT:
 *
 * In order to make this pipeline work, the following configuration on Jenkins is required:
 * - slave with a specific label (see pipeline.agent.label below)
 * - credentials plugin should be installed and have the secrets with the following names:
 *   + lciadm100credentials (token to access Artifactory)
 */

def defaultBobImage = 'armdocker.rnd.ericsson.se/sandbox/adp-staging/adp-cicd/bob.2.0:2.2.6'
def bob = new BobCommand()
        .bobImage(defaultBobImage)
        .envVars([ISO_VERSION: '${ISO_VERSION}'])
        .needDockerSocket(true)
        .toString()
def GIT_COMMITTER_NAME = 'enmadm100'
def GIT_COMMITTER_EMAIL = 'enmadm100@ericsson.com'
def failedStage = ''
pipeline {
    agent {
        label 'Cloud-Native-Remotedesktop'
    }
    parameters {
        string(name: 'ISO_VERSION', description: 'The ENM ISO version (e.g. 1.65.77)')
        string(name: 'SPRINT_TAG', description: 'Tag for GIT tagging the repository after build')
        string(name: 'PRODUCT_SET', description: 'cENM product set (e.g. 21.01.01-1)')
        string(name: 'BRANCH', description: 'Branch to build')
    }
    environment {
        GERRIT_HTTP_CREDENTIALS_FUser = credentials('FUser_gerrit_http_username_password')
    }
    stages {
        stage('Clean up tmp directory') {
            steps {
                sh "rm -rf ${WORKSPACE}/tmp/*.*"
            }
        }
        stage('Clean up Docker Images') {
            steps {
                    sh '''    
                        docker system prune -af
                    '''
            }
        }
        stage('Inject Credential Files') {
            steps {
                withCredentials([file(credentialsId: 'lciadm100-docker-auth', variable: 'dockerConfig')]) {
                    sh "install -m 600 ${dockerConfig} ${HOME}/.docker/config.json"
                }
            }
        }
        stage('Checkout Cloud-Native SG Git Repository') {
            steps {
                git branch: 'master',
                        credentialsId: 'FUser_gerrit_http_username_password',
                        url: 'https://${GERRIT_MIRROR_HTTP_E2E}/OSS/ENM-Parent/SQ-Gate/com.ericsson.oss.containerisation/eric-enmsg-remotedesktop'
                sh '''
                    "/usr/bin/git" remote set-url origin --push https://${GERRIT_HTTP_CREDENTIALS_FUser}@${GERRIT_CENTRAL_HTTP_E2E}/OSS/ENM-Parent/SQ-Gate/com.ericsson.oss.containerisation/eric-enmsg-remotedesktop
                '''
            }     
        }
        stage('Check podman setup ') {
            steps {
                sh "podman info; docker info"
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('Environment info') {
            steps {
                sh "printenv; echo $USER;"
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('Helm Dep Up ') {
            steps {
                sh "${bob} helm-dep-up"
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('Merge values files') {
            steps {
                script {
                    appconfig_values = sh (script: "ls ${WORKSPACE}/chart/eric-enmsg-remotedesktop/appconfig/ | grep values.yaml", returnStatus: true)
                    if (appconfig_values == 0) {
                        sh("${bob} merge-values-files-with-appconfig")
                    } else {
                        sh("${bob} merge-values-files")
                    }
                    sh '''
                         if /usr/bin/git status | grep 'values.yaml' > /dev/null; then
                            /usr/bin/git add chart/eric-enmsg-remotedesktop/values.yaml
                            /usr/bin/git commit -m "NO JIRA - Merging Values.yaml file with common library values.yaml"
                         fi
                     '''
                }
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('Helm Lint') {
            steps {
                sh "${bob} lint-helm"
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('Linting Dockerfile') {
            steps {
                sh "${bob} lint-dockerfile"
                archiveArtifacts '*dockerfilelint.log'
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('ADP Helm Design Rule Check') {
            steps {
                sh "${bob} test-helm || true"
                archiveArtifacts 'design-rule-check-report.*'
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('Swap versions in Dockerfile and values.yaml file') {
            steps {
                echo sh(script: 'env', returnStdout: true)
                step([$class: 'CopyArtifact', projectName: 'sync-build-trigger', filter: "*"]);
                sh "${bob} swap-latest-versions-with-numbers"
                sh '''
                     if /usr/bin/git status | grep 'Dockerfile\\|values.yaml' > /dev/null; then
                        /usr/bin/git commit -m "NO JIRA - Updating Dockerfile and Values.yaml files with base images version"
                        /usr/bin/git push origin HEAD:master
                     else
                        echo `date` > timestamp
                        /usr/bin/git add timestamp
                        /usr/bin/git commit -m "NO JIRA - Time Stamp "
                        /usr/bin/git push origin HEAD:master
                     fi
                 '''
            }
        }
        stage('Build Image and Chart') {
            steps {
                sh "rm -rf ${WORKSPACE}/tmp"
                sh "mkdir -p ${WORKSPACE}/tmp/cache/zypp ${WORKSPACE}/tmp/var/log"
                sh "date"
                sh "${bob} generate-new-version build-helm build-image-with-all-tags"
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                         sh "${bob} remove-image-with-all-tags"
                    }
                }
            }
        }
        stage('Retrieve image version') {
            steps {
                script {
                    env.IMAGE_TAG = sh(script: "cat .bob/var.version", returnStdout: true).trim()
                    echo "${IMAGE_TAG}"
                }
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                         sh "${bob} remove-image-with-all-tags"
                    }
                }
            }
        }
        stage('Generate ADP Parameters') {
            steps {
                sh "${bob} generate-output-parameters"
                archiveArtifacts 'artifact.properties'
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
            }
        }
        stage('Publish Images to Artifactory') {
            steps {
                sh "${bob} push-image-with-all-tags"
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                        sh "${bob} remove-image-with-all-tags"
                    }
                }
                always {
                    script {
                        sh "${bob} remove-image-with-all-tags"
                    }
                }
            }
        }
        stage('Publish Helm Chart') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'lciadm100', variable: 'HELM_REPO_TOKEN')]) {
                        def bobWithHelmToken = new BobCommand()
                                .envVars(['HELM_REPO_TOKEN': env.HELM_REPO_TOKEN])
                                .toString()
                        sh "${bobWithHelmToken} push-helm"
                    }
                }
            }
        }
        stage('Tag Cloud-Native SG Git Repository') {
            steps {
                wrap([$class: 'BuildUser']) {
                    script {
                        def bobWithCommitterInfo = new BobCommand()
                                .envVars([
                                        'AUTHOR_NAME'        : "\${BUILD_USER:-${GIT_COMMITTER_NAME}}",
                                        'AUTHOR_EMAIL'       : "\${BUILD_USER_EMAIL:-${GIT_COMMITTER_EMAIL}}",
                                        'GIT_COMMITTER_NAME' : "${GIT_COMMITTER_NAME}",
                                        'GIT_COMMITTER_EMAIL': "${GIT_COMMITTER_EMAIL}"
                                ])
                                .toString()
                        sh "${bobWithCommitterInfo} create-git-tag"
                        sh """
                            tag_id=\$(cat .bob/var.version)
                            "/usr/bin/git" push origin \${tag_id}
                        """
                    }
                }
            }
            post {
                failure {
                    script {
                        failedStage = env.STAGE_NAME
                    }
                }
                always {
                    script {
                        sh "${bob} remove-git-tag"
                    }
                }
            }
        }
        stage('Generate Metadata Parameters') {
            steps {
                sh "${bob} generate-metadata-parameters"
                archiveArtifacts 'image-metadata-artifact.json'
            }
        }
    }
    post {
        success {
            script {
                sh '''
                    set +x
                    "/usr/bin/git" tag --annotate --message "Tagging latest in sprint" --force $SPRINT_TAG HEAD
                    "/usr/bin/git" push --force origin $SPRINT_TAG
                    "/usr/bin/git" tag --annotate --message "Tagging latest in sprint with ISO version" --force ${SPRINT_TAG}_iso_${ISO_VERSION} HEAD
                    "/usr/bin/git" push --force origin ${SPRINT_TAG}_iso_${ISO_VERSION}
                    "/usr/bin/git" tag --annotate --message "Tagging latest in sprint with Product Set version" --force ps_${PRODUCT_SET} HEAD
                    "/usr/bin/git" push --force origin ps_${PRODUCT_SET}
                '''
            }
        }
        failure {
            mail to: 'PDLENMOUTS@pdl.internal.ericsson.com',
                    subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                    body: "Failure on ${env.BUILD_URL}"
        }
    }
}

// More about @Builder: http://mrhaki.blogspot.com/2014/05/groovy-goodness-use-builder-ast.html
import groovy.transform.builder.Builder
import groovy.transform.builder.SimpleStrategy

@Builder(builderStrategy = SimpleStrategy, prefix = '')
class BobCommand {
    def bobImage = 'bob.2.0:2.2.6'
    def envVars = [:]
    def needDockerSocket = false

    String userHome = System.getProperty('user.home');

    String toString() {
        def env = envVars
                .collect({ entry -> "export ${entry.key}=\"${entry.value}\";" })
                .join(' ')

        def cmd = """\
            |${env}
            |${userHome}/bin/bob
            |--workdir \${PWD}
            |"""
        return cmd
                .stripMargin()           // remove indentation
                .replace('\n', ' ')      // join lines
                .replaceAll(/[ ]+/, ' ') // replace multiple spaces by one
    }
}
