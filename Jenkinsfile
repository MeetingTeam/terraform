pipeline{
          agent {
                    kubernetes {
                              inheritFrom 'terraform'
                    }
          }

          parameters {
                    choice(choices: ['dev', 'prod'], name: 'ENV', description: 'Select environment to apply terraform')
          }

          environment {
                    AWS_ACCESS_KEY_ID = credentials('awsAccessKeyId')
                    AWS_SECRET_ACCESS_KEY = credentials('awsSecretAccessKey')
                    AWS_DEFAULT_REGION = 'ap-southeast-1'
          }

          stages {
                    stage('Initializing Terraform'){
                              steps {
                                        container('terraform') {
                                                  dir("environments/${params.ENV}"){
                                                            sh 'terraform init -no-color'
                                                  }
                                        }    
                              }
                    }
                    stage('Validating Terraform'){
                              steps {
                                    container('terraform') {
                                          dir("environments/${params.ENV}"){
                                                sh 'terraform validate -no-color'
                                          }
                                    }
                              }
                    }
                    stage('Terraform Plan'){
                              steps {
                                        container('terraform') {
                                                dir("environments/${params.ENV}"){
                                                      sh 'terraform plan -var-file=terraform.tfvars -no-color'
                                                }
                                        }
                              }
                    }
                  stage('Approval') {
                        when {
                              expression { params.ENV == 'prod' }
                        }
                        steps {
                              timeout(time: 30, unit: "MINUTES") {
                                    input(message: "PRODUCTION DEPLOYMENT: Are you sure you want to apply these Terraform changes?", ok: "Yes, deploy to PRODUCTION")
                              }
                        }
                  }
                  stage('Dev Approval') {
                        when {
                              expression { params.ENV == 'dev' }
                        }
                        steps {
                              timeout(time: 10, unit: "MINUTES") {
                                    input(message: "Apply changes to DEV environment?", ok: "Yes, apply")
                              }
                        }
                  }
                  stage('Terraform Apply'){
                        steps {
                              container('terraform') {
                                    dir("environments/${params.ENV}"){
                                          sh 'terraform apply -var-file=terraform.tfvars -auto-approve -no-color' 
                                    }
                              }
                        }
                  }
          }
}
