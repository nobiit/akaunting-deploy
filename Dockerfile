FROM php:8.1-apache

ARG AKAUNTING_DOCKERFILE_VERSION=0.1
ARG SUPPORTED_LOCALES="en_US.UTF-8"

RUN apt-get update \
 && apt-get -y upgrade --no-install-recommends \
 && apt-get install -y \
    build-essential \
    imagemagick \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libonig-dev \
    libpng-dev \
    libpq-dev \
    libssl-dev \
    libxml2-dev \
    libxrender1 \
    libzip-dev \
    locales \
    openssl \
    unzip \
    zip \
    zlib1g-dev \
    git \
    sudo \
    --no-install-recommends \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN for locale in ${SUPPORTED_LOCALES}; do \
    sed -i 's/^# '"${locale}/${locale}/" /etc/locale.gen; done \
 && locale-gen

RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
 && docker-php-ext-install -j$(nproc) \
    gd \
    bcmath \
    intl \
    mbstring \
    pcntl \
    pdo \
    pdo_mysql \
    zip

RUN curl -sL https://getcomposer.org/installer | php && \
    mv $(pwd)/composer.phar /usr/local/bin/composer

RUN curl -sL https://nodejs.org/dist/v16.18.0/node-v16.18.0-linux-x64.tar.xz | tar -xJC /usr/local/ --strip-components 1

RUN rm -rf /var/www/html/* && \
    sudo -u www-data git clone https://github.com/nobiit/akaunting.git /var/www/html

RUN chown www-data: ~www-data
RUN sudo -u www-data composer install
RUN sudo -u www-data npm install
RUN sudo -u www-data npm run dev

COPY files/akaunting.sh /usr/local/bin/akaunting.sh
COPY files/html /var/www/html

RUN cp ${PHP_INI_DIR}/php.ini-development ${PHP_INI_DIR}/php.ini
RUN sed -i -E 's/^(memory_limit =) .+$/\1 1G/' ${PHP_INI_DIR}/php.ini

ENTRYPOINT ["/usr/local/bin/akaunting.sh"]
CMD ["--start"]
