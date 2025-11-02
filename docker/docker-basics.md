# docker basics (beginner)

this is a small cheat sheet for docker command line  
for quick lookup when stuck

---

## check version
    docker --version

## pull image (download)
    sudo docker pull <image>

## run image (one time)
    sudo docker run <image>

## run in background (detached)
    sudo docker run -d <image>

## run with port mapping (host:container)
    sudo docker run -d -p 8080:80 <image>

## list running containers
    sudo docker ps

## list ALL containers (also stopped)
    sudo docker ps -a

## stop container (use container ID)
    sudo docker stop <id>

## remove container
    sudo docker rm <id>

## remove image
    sudo docker rmi <image>

## remove ALL stopped containers
    sudo docker container prune

---

## useful test images
    sudo docker run hello-world
    sudo docker run -d -p 8080:80 nginx
