github actions is used to automate the process of modifying, testing and deploying your app.

usually there are three fases of testing:
    - local testing: fast
    - CI testing: unit tests, integration tests
    - CD testing: slow

the yaml file sintax:

name: describes your workflow

on: events that trigger the workflow, they have a list of events that can trigger the workflow on their docs

jobs: groups a set of actions that will be executed

whenever we are referring to an action, we use "uses:" and when we refer to commands we use "run:"

every "job" you create takes a different github server. they all run in parallel but you can set one job to start after other, by putting "needs:name_of_the_other_job"

when wrinting the commands in "runs:", its possible to write multiple commands.
EX: run docker
runs: |
    docker build
    docker compose up
    ...

it is possible to use placeholders called "secrets", to keep variable that you want to hide, can create them in settings on github
EX: username: ${{secrets.DOCKER_USERNAME}}
    password: ${{secrets.DOCKER_PASSWORD}}

there are some useful variables in github:
    - github.sha → tag única pra cada versão da imagem
    - github.run_number → contador incremental (build #1, #2, #3...)
    - github.actor → quem triggerou o workflow

the checkout part does the installation of things and clone the repo

the best way to deploy the container in my EC2 instance, is by building, pushing to Docker Hub and 
do docker pull inside the instance
this approach is more scalable

when building a docker image inside the docker hub, you need to put the name as:
docker build -t ${{ secrets.DOCKER_USERNAME }}/my-portfolio:${{ github.sha }}

sha basically gives a unique tag for the commit, useful for keeping old versions of your program
can do rollback
but for simplicity, i'm gonna use ":latest", it replaces the last commit

