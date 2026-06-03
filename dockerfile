FROM jenkins/jenkins:lts
USER root

# Install PHP, extensions needed by Composer, and Docker CLI
RUN apt-get update && apt-get install -y \
    php \
    php-cli \
    php-zip \
    php-xml \
    php-mbstring \
    php-curl \
    unzip \
    curl \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Allow jenkins user to run docker commands
RUN usermod -aG docker jenkins

USER jenkins
