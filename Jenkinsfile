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
                        steps {
                              timeout(time: 15, unit: "MINUTES") {
                                    input(message: "Are you sure you want to apply these Terraform changes?", ok: "Yes, apply")
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