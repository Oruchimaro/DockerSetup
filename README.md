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

## Nginx Setup

```yml
	nginx:
		image: nginx:stable-alpine # build nginx stable and alpine linux
		container_name: nginx #fullname of container after its creation
		ports: # make connection between docker container ports ans system
			- 80:80  # system-port:container-port
			- 443:443
		network: # Add the network to the container
			- laravel-network
```

We want to replace the default welcome page from nginx, we will create a `src/index.html`
file that contains our own code.

```html
<h1>H3llo from inside nginx</h1>
```

now under the ports setting we will add new attribute :

```yml
	nginx:
		image: nginx:stable-alpine # build nginx stable and alpine linux
		container_name: nginx #fullname of container after its creation
		ports: # make connection between docker container ports ans system
			- 80:80  # system-port:container-port
			- 443:443
		volumes: # make local files available to container
			- ./src:/var/www/html
		network: # Add the network to the container
			- laravel-network
```

If the page is not showing then

- login to nginx contaner `docker exec nginx /bin/sh`
- check the `/var/www/html` and see the file is there
- check the default nginx config `cat /etc/nginx/conf.d`
- if the serving directory is different then change the compose file `- ./src:/usr/share/nginx/html`

## Change the default conf of nginx

First create a config file in local machine :

```shell
mkdir nginx && cd nginx

touch default.conf

```

```
server {
	listen 80;
	listen [::]:80;
	index index.php index.html;
	server_name localhost;
	root /var/www/html;

	add_header X-Frame-Options "SAMEORIGIN";
	add_header X-Content-Type-Options "nosniff";
	charset utf-8;

	location / {
		try_files $uri $uri/ /index.php?$query_string;
	}

	location = /favicon.ico { access_log off; log_not_found off; }
	location = /robots.txt { access_log off; log_not_found off; }

	error_page 404 /index.php;

	location ~ \.php$ {
		fstcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass php:9000; #The php container
		fastcgi_index index.php;

		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		fastcgi_param PATH_INFO $fastcgi_path_info;
		fastcgi_hide_header X-Powered-By;
	}

	location ~ /\.(?!well-known).* {
		deny all;
	}
}
```

Then we need to build the nginx service (replace image with build) :

```yml
	nginx:
		build:
		    context: ./docker/develop/nginx
      		dockerfile: nginx.dockerfile  #we need a file for nginx to build from
		container_name: nginx #fullname of container after its creation
		ports: # make connection between docker container ports ans system
			- 80:80  # system-port:container-port
			- 443:443
		volumes: # make local files available to container
			- ./src:/var/www/html
		network: # Add the network to the container
			- laravel-network
```

now the docker file :

```shell
touch nginx.dockerfile # in the same directory as docker-compose.yml

# nginx.dockerfile
FROM nginx:stable-alpine
ADD ./nginx/default.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /var/www/html
```

Now build and run the service :

```
docker-compose up -d --build
```

## PHP-FPM setup

Change the `src/index.hmtl` file to `src/index.php`

```php
<?php

phpinfo();
```

```yml
	php:
		image: php:8.3-fpm-alpine # build php-fpm version 7.4 and alpine linux
		container_name: php #fullname of container after its creation
		network: # Add the network to the container
			- laravel-network
		volumes: # make local php files available to container
			- ./src:/var/www/html
```

```shell
docker-compose up -d --build

# visit localhost : it should display phpinfo
```

We need to have pdo mysql extension, so we can build our own php container :

```yml
	php:
		build:
			context: .
			dockerfile: php.dockerfile
		container_name: php #fullname of container after its creation
		network: # Add the network to the container
			- laravel-network
		volumes: # make local php files available to container
			- ./src:/var/www/html
```

now the docker file :

```shell
touch php.dockerfile # in the same directory as docker-compose.yml

# php.dockerfile
FROM php:8.3-fpm-alpine

RUN docker-php-ext-install pdo pdo_mysql # install php extension easily
```

```shell
docker-compose up -d --build

# visit localhost : it should display phpinfo
```

## Fix permission issues

```shell
docker-compose exec php /bin/sh


cd /usr/local/etc/php-pm.d/
cat www.conf

# see the Unix user/group
user = www-data
group = www-data
```

so change the `php.dockerfile` :

```shell
# php.dockerfile
FROM php:8.3-fpm-alpine

RUN mkdir -p /var/www/html

RUN apk --no-cache add shadow && usermod -u 1000 www-data
# we are telling apk (alpine package manager) to install shadow
# we are going to use shadow to access usermod
# with usermod add 1000 (default id of root user) to www-data group

RUN docker-php-ext-install pdo pdo_mysql # install php extension easily
```

```shell
docker-compose up -d --build

# visit localhost : it should display phpinfo

docker compose exec php /bin/sh

ls -la  # check the permissions
```
