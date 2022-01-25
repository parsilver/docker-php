FROM alpine:3.15

RUN apk --no-cache add \
  curl \
  nginx \
  php8 \
  php8-ctype \
  php8-curl \
  php8-dom \
  php8-fpm \
  php8-gd \
  php8-intl \
  php8-json \
  php8-mbstring \
  php8-pdo \
  php8-pdo_mysql \
  php8-mysqli \
  php8-redis \
  php8-opcache \
  php8-openssl \
  php8-phar \
  php8-session \
  php8-pcntl \
  php8-simplexml \
  php8-posix \
  php8-zlib \
  php8-zip \
  php8-exif \
  php8-fileinfo \
  php8-tokenizer \
  supervisor

RUN ln -s /usr/bin/php8 /usr/bin/php

# Configure nginx
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY .docker/php/fpm-pool.conf /etc/php8/php-fpm.d/www.conf
COPY .docker/php/php.ini /etc/php8/conf.d/custom.ini

# Configure supervisord
COPY .docker/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer;

# Setup document root
RUN mkdir -p /var/www/project/public

# Add application
WORKDIR /var/www/project

COPY . /var/www/project/

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/project/public && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

EXPOSE 8080

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
