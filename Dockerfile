#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#
# To edit the 'php-fpm' base Image, visit its repository on Github
#    https://github.com/Linc70J/php-fpm
#
# To change its version, see the available Tags on the Docker Hub:
#    https://hub.docker.com/r/linc70j/php-fpm
#

# FROM laradock/php-fpm:2.2-${LARADOCK_PHP_VERSION}
FROM letsdockerize/laradock-php-fpm:2.4-7.2

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

# Set Environment Variables
ENV DEBIAN_FRONTEND noninteractive

# always run apt update when start and after add new source list, then clean up at end.
RUN set -xe; \
    apt-get update -yqq && \
    pecl channel-update pecl.php.net && \
    apt-get install -yqq \
      apt-utils vim supervisor \
      libzip-dev zip unzip && \
      docker-php-ext-configure zip --with-libzip && \
      docker-php-ext-install zip && \
      php -m | grep -q 'zip'

#
#--------------------------------------------------------------------------
# Optional Software's Installation
#--------------------------------------------------------------------------
#
# Optional Software's will only be installed if you set them to `true`
# in the `docker-compose.yml` before the build.
# Example:
#   - INSTALL_SOAP=true
#


###########################################################################
# composer:
###########################################################################

RUN mkdir /tmp/composer \
    && cd /tmp/composer; curl -sS https://getcomposer.org/installer | php; cd - \
    && mv /tmp/composer/composer.phar /usr/local/bin/composer

###########################################################################
# Swoole EXTENSION
###########################################################################

USER root

RUN if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      pecl install swoole-2.0.10; \
    else \
      if [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ]; then \
        pecl install swoole-2.2.0; \
      else \
        pecl install swoole; \
      fi \
    fi && \
    docker-php-ext-enable swoole \
    && php -m | grep -q 'swoole'

###########################################################################
# bcmath:
###########################################################################

RUN docker-php-ext-install bcmath

###########################################################################
# Opcache:
###########################################################################

RUN docker-php-ext-install opcache

# Copy opcache configration
COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini

###########################################################################
# Human Language and Character Encoding Support:
###########################################################################

# Install intl and requirements
RUN apt-get install -y zlib1g-dev libicu-dev g++ && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl

###########################################################################
# Image optimizers:
###########################################################################

USER root

RUN apt-get install -y jpegoptim optipng pngquant gifsicle

###########################################################################
# ImageMagick:
###########################################################################

USER root

RUN apt-get install -y libmagickwand-dev imagemagick && \
    pecl install imagick && \
    docker-php-ext-enable imagick

###########################################################################
# Check PHP version:
###########################################################################

RUN set -xe; php -v | head -n 1 | grep -q "PHP 7.2."

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

COPY laravel.ini /usr/local/etc/php/conf.d
COPY xlaravel.pool.conf /usr/local/etc/php-fpm.d/

USER root

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog