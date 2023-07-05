FROM alpine:3.16
LABEL Maintainer="Ben Thai <vietstar.nt@gmail.com>" \
      Description="Lightweight container with Nginx 1.22 & PHP-FPM 8 based on Alpine Linux."

ARG PHP_VERSION="8.0.28-r0"

# https://github.com/wp-cli/wp-cli/issues/3840
ENV PAGER="more"

# Install packages and remove default server definition
RUN apk --no-cache add php8=${PHP_VERSION} \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-exif \
    php8-fileinfo \
    php8-fpm \
    php8-gd \
    php8-iconv \
    php8-intl \
    php8-mbstring \
    php8-mysqli \
    php8-opcache \
    php8-openssl \
    php8-pecl-imagick \
    php8-pecl-redis \
    php8-phar \
    php8-session \
    php8-simplexml \
    php8-soap \
    php8-xml \
    php8-xmlreader \
    php8-zip \
    php8-zlib \
    php8-pdo \
    php8-xmlwriter \
    php8-tokenizer \
    php8-pdo_mysql \
    php8-pdo_sqlite \
    php8-xdebug \
    nginx supervisor curl tzdata htop mysql-client dcron;

# Symlink php8 => php
# RUN ln -s /usr/bin/php8 /usr/bin/php

# Install PHP tools
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Install Node.js
RUN apk add nodejs npm

# Configure certs
COPY config/certs /etc/nginx/certs

# Configure nginx
COPY config/web/nginx/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/web/nginx/fpm-pool.conf /etc/php8/php-fpm.d/www.conf
COPY config/web/php/php.ini /etc/php8/conf.d/custom.ini

# Configure supervisord
COPY config/web/nginx/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/dev.org/html/public

#add vendor folder for laravel
# RUN mkdir -p /var/www/dev.org/html/vendor

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/dev.org/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx;

# Switch to use a non-root user from here on
USER nobody

WORKDIR /var/www/dev.org/html

#RUN cp .env.example .env
#RUN composer install
#RUN php artisan key:generate 

# Expose the port nginx is reachable on
EXPOSE 80 443

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
