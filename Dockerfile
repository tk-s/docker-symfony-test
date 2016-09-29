FROM debian:latest
MAINTAINER Tobias Knipping <knipping@tk-schulsoftware.de>

# Enable Backports
RUN awk '$1 ~ "^deb" { $3 = $3 "-backports"; print; exit }' /etc/apt/sources.list > /etc/apt/sources.list.d/backports.list
# Update the package repository
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \ 
	DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl locales git ca-certificates unzip

# Configure timezone and locale
RUN echo "Europe/Berlin" > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata
RUN export LANGUAGE=de_DE.UTF-8 && \
	export LANG=de_DE.UTF-8 && \
	export LC_ALL=de_DE.UTF-8 && \
	locale-gen de_DE.UTF-8 && \
	DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
  
# Install Postgres and Java (for SonarScanner)
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  DEBIAN_FRONTEND=noninteractive apt-get update -yqq && \
  DEBIAN_FRONTEND=noninteractive apt-get install postgresql-9.5 postgresql-contrib-9.5 libpq-dev openjdk-8-jre-headless -yqq

RUN curl --location --output /opt/sonar-scanner-2.8.zip https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-2.8.zip && \
  unzip /opt/sonar-scanner-2.8.zip -d /opt/ && \
  chmod 777 -R /opt/sonar-scanner-2.8/bin

# Added dotdeb to apt
RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
	echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
	wget -O- http://www.dotdeb.org/dotdeb.gpg | apt-key add -
  
# Install PHP 7.0
RUN DEBIAN_FRONTEND=noninteractive apt-get update -yqq; \
  DEBIAN_FRONTEND=noninteractive apt-get install -y php7.0 php7.0-apcu php7.0-cli php7.0-common php7.0-curl php7.0-dev php7.0-gd php7.0-igbinary php7.0-intl php7.0-json php7.0-ldap php7.0-mbstring php7.0-mcrypt php7.0-memcached php7.0-msgpack php7.0-opcache php7.0-pgsql php7.0-readline php7.0-redis php7.0-xml
 
# Let's set the default timezone in both cli and apache configs
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Berlin/g' /etc/php/7.0/cli/php.ini

# Setup Composer
RUN curl -sS https://getcomposer.org/installer | php && \
	mv composer.phar /usr/local/bin/composer

# Setup PHPUnit
RUN curl --location --output /usr/local/bin/phpunit https://phar.phpunit.de/phpunit.phar && \
  chmod +x /usr/local/bin/phpunit


# Adding letsencrypt-ca to truststore
RUN export KEYSTORE=/etc/ssl/certs/java/cacerts && \
    wget -P /tmp/ https://letsencrypt.org/certs/letsencryptauthorityx1.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/letsencryptauthorityx2.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x2-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias isrgrootx1 -file /tmp/letsencryptauthorityx1.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias isrgrootx2 -file /tmp/letsencryptauthorityx2.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx1 -file /tmp/lets-encrypt-x1-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx2 -file /tmp/lets-encrypt-x2-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx3 -file /tmp/lets-encrypt-x3-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx4 -file /tmp/lets-encrypt-x4-cross-signed.der

CMD ["php", "-a"]
