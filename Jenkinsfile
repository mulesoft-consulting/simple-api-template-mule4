//returns the deployment env name according to branch name
//otherwise it raises an exception if the branch name is not recognized
def getDeployEnv(git_branch) {
  if(!git_branch){
    throw new Error("branch ${git_branch} is not valid.")
  }
  String bname = parseBranchName(git_branch) 
  switch(bname) {
    case ~/dev/ : return "DEV";
    case ~/qa/: return "QA";
    case ~/uat/: return "UAT";
    default: throw new Exception ("branch ${git_branch} not recognized.");
  }
}

//returns the type of the environment according to the branch name e.g sandbox or production
def getEnvType (git_branch) {
  if(!git_branch){
    throw new Error("branch ${git_branch} is not valid.")
  }
  String bname = parseBranchName(git_branch) 
  switch(bname) {
    case ~/(dev)|(qa)|(uat)/: return 'sandbox';
    default: throw new Exception ("branch ${git_branch} not recognized.");
  }
}

//returns environment name mapped to the git branch
def getMappedEnv (git_branch) {
  if(!git_branch){
    throw new Error("branch ${git_branch} is not valid.")
  }
  String bname = parseBranchName(git_branch) 
  String name;
  switch(bname) {
    case ~/dev/ : name = "dev"; break;
    case ~/qa/: name = "qa"; break;
    case ~/uat/: name = "uat"; break;
    default: throw new Exception ("branch ${git_branch} not recognized.");
  }
  return name
}

//removes the origin/ from the branch name
def parseBranchName (git_branch) {
  if(!git_branch){
    throw new Error("branch ${git_branch} is not valid.")
  }
  def (_,name) = (git_branch =~ /^origin\/(.+)$/)[0]
  return name
}

//parses the git url to extract repo name 
def parseRepoName (git_url) {
  if(!git_url){
    throw new Error("git url ${git_url} is not valid.")
  }
  def (_,head,name) = (git_url =~ /^(git@|https:\/\/).*\/(.*)\.git$/)[0]
  return name
}


/* 
  PIPELINE 

  *** CREDENTIALS REQUIREMENTS ***
  following is a list of nomenclature for credentials used in this pipeline.
    ** anypoint platform environment credentials. should be provided for each environment as "Secret text". 
      The name is generated from the git branch:
          - anypoint.{env}.client_id 
          - anypoint.{env}.secret_id 
    ** anypoint connected app credentials. should be provided for each environment as "Secret text".
      All environments below production use a single user and production has its own user.
      The cred key is generated from the git branch. see the "getEnvType" for the implementation of env descrimination:
          - anypoint.app.{sandbox/production}.client_id
          - anypoint.app.{sandbox/production}.client_secret
    ** mule vault key credential. should be provided for each project as "Secret text".
      the project name is extracted from the git url. See "parseRepoName" for project name extraction:  
          - anypoint.vault.{project_name}.{env}.key
  ********************************************************
  
 */
pipeline {
  agent any
  tools { 
    maven 'Maven 3.6.3' 
    jdk 'jdk8' 
  }
  environment {
    PROJECT_NAME = parseRepoName(GIT_URL)
    ENV_TYPE = getEnvType(GIT_BRANCH)

    ENV = getMappedEnv(GIT_BRANCH)
    ANYPOINT_ENV = getDeployEnv(GIT_BRANCH)
    ANYPOINT_REGION = "eu-central-1"
    ANYPOINT_BUSINESS_GROUP = "Cargo"
    ANYPOINT_WORKER_TYPE = "MICRO"
    ANYPOINT_WORKERS = "1"
    ANYPOINT_HOST = "https://eu1.anypoint.mulesoft.com"
    ANYPOINT_ANALYTICS_HOST = "https://analytics-ingest.eu1.anypoint.mulesoft.com"

    ANYPOINT_VAULT_CRED_KEY = "anypoint.vault.${PROJECT_NAME}.${ENV}.key"
    
    ANYPOINT_ENV_CLIENT_ID_KEY = "anypoint.${ENV}.client_id"
    ANYPOINT_ENV_CLIENT_SECRET_KEY = "anypoint.${ENV}.client_secret"
    
    ANYPOINT_APP_CLIENT_ID_KEY = "anypoint.app.${ENV_TYPE}.client_id"
    ANYPOINT_APP_CLIENT_SECRET_KEY = "anypoint.app.${ENV_TYPE}.client_secret"

    MVN_SETTING_FILE_ID = "qa-cargo-mvn-settings"
  } 
  stages {

    stage ('Initialization') {
      steps {
        echo "PROJECT_NAME = $PROJECT_NAME"
        echo "ENV_TYPE = $ENV_TYPE"
        echo "ENV = $ENV"
        echo "ANYPOINT_ENV = $ANYPOINT_ENV"
        echo "ANYPOINT_ENV_CLIENT_ID_KEY = $ANYPOINT_ENV_CLIENT_ID_KEY"
        echo "ANYPOINT_ENV_CLIENT_SECRET_KEY = $ANYPOINT_ENV_CLIENT_SECRET_KEY"
        echo "ANYPOINT_APP_CLIENT_ID_KEY = $ANYPOINT_APP_CLIENT_ID_KEY"
        echo "ANYPOINT_APP_CLIENT_SECRET_KEY = $ANYPOINT_APP_CLIENT_SECRET_KEY"
      }
    }

    stage('MULE TEST') { 
      environment{
        ANYPOINT_VAULT_KEY = credentials("${ANYPOINT_VAULT_CRED_KEY}")
        
        ANYPOINT_APP_CLIENT_ID = credentials("${ANYPOINT_APP_CLIENT_ID_KEY}")
        ANYPOINT_APP_CLIENT_SECRET = credentials("${ANYPOINT_APP_CLIENT_SECRET_KEY}")
        
        ACCESS_TOKEN = sh (script: "curl -s 'https://eu1.anypoint.mulesoft.com/accounts/api/v2/oauth2/token' \
          -X POST -H 'Content-Type: application/json' \
          -d '{\"grant_type\": \"client_credentials\", \"client_id\": \"${ANYPOINT_APP_CLIENT_ID}\", \"client_secret\": \"${ANYPOINT_APP_CLIENT_SECRET}\"}' \
          | sed -n 's|.*\"access_token\":\"\\([^\"]*\\)\".*|\\1|p'", returnStdout: true).trim()
      }
      steps {
        echo 'Testing ...'
        configFileProvider([configFile(fileId: "${MVN_SETTING_FILE_ID}", variable: 'MAVEN_SETTINGS_XML')]) {
          sh '''
            mvn -s $MAVEN_SETTINGS_XML clean test \
              -Denv=${ENV} \
              -Danypoint.base_uri=${ANYPOINT_HOST} \
              -DauthToken=${ACCESS_TOKEN} \
              -Dmule.vault.key=${ANYPOINT_VAULT_KEY} \
          '''
        }
      }
    }

    stage ('MULE DEPLOY') {
      environment {
        ANYPOINT_VAULT_KEY = credentials("${ANYPOINT_VAULT_CRED_KEY}")

        ANYPOINT_ENV_CLIENT_ID = credentials("${ANYPOINT_ENV_CLIENT_ID_KEY}")
        ANYPOINT_ENV_CLIENT_SECRET = credentials("${ANYPOINT_ENV_CLIENT_SECRET_KEY}")
        
        ANYPOINT_APP_CLIENT_ID = credentials("${ANYPOINT_APP_CLIENT_ID_KEY}")
        ANYPOINT_APP_CLIENT_SECRET = credentials("${ANYPOINT_APP_CLIENT_SECRET_KEY}")
        
        ACCESS_TOKEN = sh (script: "curl -s 'https://eu1.anypoint.mulesoft.com/accounts/api/v2/oauth2/token' \
          -X POST -H 'Content-Type: application/json' \
          -d '{\"grant_type\": \"client_credentials\", \"client_id\": \"${ANYPOINT_APP_CLIENT_ID}\", \"client_secret\": \"${ANYPOINT_APP_CLIENT_SECRET}\"}' \
          | sed -n 's|.*\"access_token\":\"\\([^\"]*\\)\".*|\\1|p'", returnStdout: true).trim()
      }
      steps {
        echo 'Deploying ...'
        configFileProvider([configFile(fileId: "${MVN_SETTING_FILE_ID}", variable: 'MAVEN_SETTINGS_XML')]) {
          sh '''
            mvn -s $MAVEN_SETTINGS_XML deploy -DmuleDeploy \
              -Denv=${ENV} \
              -Dmule.vault.key=${ANYPOINT_VAULT_KEY} \
              -Danypoint.base_uri=${ANYPOINT_HOST} \
              -Danypoint.analytics_base_uri=${ANYPOINT_ANALYTICS_HOST} \
              -Danypoint.environment=${ANYPOINT_ENV} \
              -Danypoint.businessgroup=${ANYPOINT_BUSINESS_GROUP} \
              -Danypoint.workers=${ANYPOINT_WORKERS} \
              -Danypoint.workertype=${ANYPOINT_WORKER_TYPE} \
              -Danypoint.region=${ANYPOINT_REGION} \
              -DauthToken=${ACCESS_TOKEN} \
              -Dplatform.client_id=${ANYPOINT_ENV_CLIENT_ID} \
              -Dplatform.client_secret=${ANYPOINT_ENV_CLIENT_SECRET} \
          '''
        }
      }
    }
  }
}


