## Start

create a `docker-compose.yml` file.

```yml
version: '3.8'  # version of docker compose

networks:
	laravel-network: # create network for container
		name: laravel-network # give a readable anme

services:
	php:
		image: php:8.3-fpm-alpine # build php-fpm version 7.4 and alpine linux
		container_name: php #fullname of container after its creation
		networks: # Add the network to the container
			- laravel-network
	mysql:
		image: mysql:latest # build mysql latest version
		container_name: mysql #fullname of container after its creation
		environment: # Adding environment variables that container expects
			MYSQL_DATABASE: laraveldb
			MYSQL_USER: laravel
			MYSQL_PASSWORD: secrect
			MYSQL_ROOT_PASSWORD: secrect
		networks: # Add the network to the container
			- laravel-network
	nginx:
		image: nginx:stable-alpine # build nginx stable and alpine linux
		container_name: nginx #fullname of container after its creation
		networks: # Add the network to the container
			- laravel-network
```

Now if we open a shell in our php container we can :

```shell
docker-compose up

docker-compose exec php /bin/sh   #open the shell

nc -vz mysql 3306

nc -vz nginx 80
```
