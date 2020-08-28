# template-api

## TEMPLATE

### Description

This project is a simple template that integrates some of MuleSoft best practices. It provides a set of standard minimalistic tools that should help you start your project quickly/efficiently.

  - **Plugins**
      - mule-maven-plugin: enriched with a configuration that goes along with the Jenkinsfile (pipeline).
      - maven-release-plugin: maven release management tool see the **Realse** section for more information on how to use it
  - **Structure**
      - Separation between interface and implementation
      - Global configuration file
      - Resources
          - property files: 
            - common property file containing environment variable common to all environments (sandbox to production) like http port, basePath etc ...
            - jsonlogger property files, used to configure the JSON Logger plugin
            - a property file for each environment DEV/QA/UAT. You can add as many as you want (just don't forget to update the jenkinsfile)
  - **Dependencies** Your organisation should add the following dependencies to exchange.
      - json-logger
      - common-error-handler
  - **CI/CD**
      - Jenkinsfile: a generic premade pipeline. Instructions to building the jenkins server are located in `ci-cd_setup.md` file.

### INSTANTIATE

Make sure the `instantiate.sh` file is executable
```bash
$ chmod +x instantiate.sh
```

Here's how to use the script 

```
$ ./instantiate.sh [api-name] [api-repo-url] []
```

## RELEASE

In order to prepare a release, execute the following : 

```bash
mvn release:clean release:prepare 
```

You will be prompted to answer a few questions about the release: 

  1) **What is the release version for ...**: the name of the release. should be something like `X.X.X`. Hit enter to accept the default
  2) **What is the SCM release tag or label for ...**: the name of the tag. The default nomenclature is `{project_name}-{version}`. Use the nomenclature `v{version}`, for example `v1.0.5`. Then hit enter.
  3) **What is the new development version for ...**: the development name or the upcoming version you will be working on (the SNAPSHOT version). It should end with `SNAPSHOT`. The pluging automatically increases the patch number. Hit enter. 

You will notice the following temporary files have been created in the root folder : 

  - **release.properties:** contains the release configuration (release tag etc ...)
  - **pom.xml.releaseBackup:** the old content of the `pom.xml` file with the previous release

After you've reviewed the release properties, execute the following to perform the release:

```bash
mvn release:perform 
```
