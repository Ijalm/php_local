FROM php:8.2-apache

WORKDIR /var/www/html

# Copy project files
COPY . .

# Download the extension installer and install extensions instantly (no heavy compiling)
RUN curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions pdo pdo_mysql

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
