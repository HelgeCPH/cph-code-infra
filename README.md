This document is related to the course Development of Large Systems at Copenhagen Business Academy (). Some parts of it build on infrastructure code and experiences from Praqma's CoDe training ().

This is a guide on how to setup an example continuous integration (CI) chain using the following technologies and tools:

  * the distributed version control system (VCS) Git (https://git-scm.com) and GitHub (https://github.com) as host,
  * the build server Jenkins (https://jenkins.io),
  * Docker containers (https://www.docker.com) and DockerHub (https://hub.docker.com) as a public registry,
  * Vagrant (https://www.vagrantup.com) to setup and manage virtual machines
  * the Maven repository manager Artifactory (https://www.jfrog.com/open-source/),
  * the application server Glassfish (http://glassfish.java.net/),
  * and the cloud server provider Digital Ocean (https://www.digitalocean.com).




Scenario
========

We have a Java project consisting of three projects, which depend on each other.

The project's source code can be found here:

  * Contracts: https://github.com/eguahlak/choir-contract
  * A mockup of a backend: https://github.com/eguahlak/choir-backend-mock
  * And a simple frontend: https://github.com/eguahlak/choir-frontend.git

In essence these Java projects form a simple web-application, which serves a list of names
The contracts project consists of a set of interfaces and data transfer objects (DTO) and is used to let different groups of students implement their frontends and backend systems independently against a common specification and mockups.

The purpose of this guide is not to detail this Java project. Instead, we just use it to illustrate some of the steps, which are required to setup a complete CI chain automatically deploying the project on a production server.

Importantly, the projects depend on each other. The backend mockup depends on the contracts and the frontend depends on the two other projects. The package dependencies -as specified in the Maven metadata (`pom.xml`) of the respective projects- are illustrated in the following.

![Packages](helgecph.github.com/cph-code-infra/docs/images/packages.png)

The contracts project and the backend mockup are build as a JAR files, whereas the frontend project is build as a WAR file.


The CI Setup
============

We have a set of distributed developers working on their local computers and collaborating on the same source code via a Git repository hosted on GitHub. Since, for this example we do not have access to a proper build server, i.e., a separate machine, we decide to setup an Ubuntu virtual machine (VirtualBox), which will host our Jenkins build server. In case you have access to a proper build server the explanations in the following apply as well except that you can skip reading the part on Vagrant and apply the provision script (``) directly on your machine.

On a remote server -hosted at Digital Ocean, you can host it anywhere else according to your liking- we have, amongst others, a Docker container running an Artifactory instance, which serves our local Maven dependencies. Finally, to the same remote machine we will automatically deploy a Docker container, which hosts our web-application with the help of a Glassfish application server.

The setup is illustrated in the following.

![CI Setup](helgecph.github.com/cph-code-infra/docs/images/ci_setup.png)




Setup Your Remote Production Machine
====================================

  * Register at Digital Ocean (https://www.digitalocean.com)
  * Create a new Ubuntu 16.04.1 droplet (smallest machine, 5$ per month)
  * Register your public SSH key (https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets)
  * SSH to your new machine and create a new user

```bash
    ssh root@your_ip
    adduser builder
    usermod -aG sudo builder
    exit
```

  * Copy the setup script to the remote machine and execute it:

```bash
    scp /path/to/setup.sh builder@139.59.151.102:/home/builder
    ssh builder@your_ip
    chmod u+x ./setup.sh
    ./setup.sh
```

Now you have a remote machine up and running with an Artifactory instance, a private Docker Registry, and an Apache webserver.


# Setup Your Local Build Machine

  * Install Vagrant and VirtualBox to your local machine (https://www.vagrantup.com/docs/installation/)
  * cd to

```bash
  vagrant up
  vagrant ssh
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```


  * copy the initial password to the field
  *
  Username: builder

  install the following plugins:
  Manage Jenkins -> Manage Plugins -> Maven Integration plugin
                                   -> Artifactory Plugin
                                   -> Jenkins SSH plugin
                                   -> CloudBees Docker Build and Publish plugin
  Manage Jenkins -> Global Tool Configuration -> Maven -> Install automatically
  setup your projects as maven projects

## Configuring Jenkins


### Creating your Build Jobs



Publish to a Docker Registry
============================
If you do not want your repository to be public by default set the standard configuration in your settings (https://hub.docker.com/account/settings/) to private. You have one private repository for a free plan.


    docker tag e29c630fcc3d helgecph/glassfish-cph:13
    docker login -u <your_user_id> -p "<your_pwd>"
    docker push helgecph/glassfish-cph:13
    docker logout


Deploy your image
=================

    ssh builder@XXX

    docker stop `docker ps -a | grep helgecph/glassfish-cph | awk '{print substr ($0, 0, 12)}'`
    docker pull helgecph/glassfish-cph
    docker run -d -ti -p 4848:4848 -p 8080:8080 helgecph/glassfish-cph

    docker stop; docker pull helgecph/glassfish-cph; docker run -d -ti -p 4848:4848 -p 8080:8080 helgecph/glassfish-cph



ssh builder@139.59.151.102 <<'ENDSSH'
ls
cat
ENDSSH


OIOIOI
======
    sudo su jenkins

    mkdir ~/.ssh/
    ssh-keyscan 139.59.151.102 > ~/.ssh/known_hosts
    exit
