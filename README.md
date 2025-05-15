# DevOps Assignment

# -	Steps on how to set up and run the CI pipeline:

1)	Forked the application repository on github to my personal repository `https://github.com/youseftarekk/node-hello`

2)	Cloned the forked repository locally “git clone `https://github.com/youseftarekk/node-hello.git”`


3)	Created a Dockerfile to containerize the application.

4)	Created a github actions pipeline “main.yml” with the following logic:

- Run on push to main branch or pull requests (to trigger the pipeline)
- Run ESLint to check the code quality
- Build the Docker image
- Push the image to my Docker Hub repository:` https://hub.docker.com/repository/docker/youssefbadawy/node-hello/general `


5)	Created a new public dockerhub repository “node-hello”

6)	Added my Dockerhub access token “DOCKER_HUB_USERNAME & DOCKER_HUB_PASSWORD” to my github repository secrets, The token created has read, write & delete permissions on the repository 


7)	For terraform before running terraform init/plan/apply; Use aws cli command “aws configure” to set the “access key id & secret access key”






