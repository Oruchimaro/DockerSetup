FROM php:8.3-fpm-alpine


# we are telling apk (alpine package manager) to install shadow
# we are going to use shadow to access usermod
# with usermod add 1000 (default id of root user) to www-data group
RUN apk --no-cache add shadow && usermod -u 1000 www-data

RUN mkdir -p /var/www/html

# install php extension easily
RUN docker-php-ext-install pdo pdo_mysql 