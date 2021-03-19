FROM php:7.3-buster

ENV S6_OVERLAY_MD5HASH e49a47715f5f187928c98e6eaba41a39
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64.tar.gz /tmp/

RUN	set -ex; \
    apt-get update && apt-get install -y --no-install-recommends \
	openssl \
	git \
	dos2unix \
	unzip; \
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
	rm -rf /var/lib/apt/lists/*;

RUN set -ex; \
    cd /tmp; \
    echo "$S6_OVERLAY_MD5HASH *s6-overlay-amd64.tar.gz" | md5sum -c -; \
    tar xzf s6-overlay-amd64.tar.gz -C /; \
    rm s6-overlay-amd64.tar.gz;

COPY .s6-svscan /var/run/s6/services/.s6-svscan/

RUN useradd -ms /bin/bash jikanapi

USER jikanapi

WORKDIR /home/jikanapi

RUN set -ex; \
    composer --version; \
    mkdir app; \
    cd app; \
    git clone https://github.com/jikan-me/jikan-rest.git .; \
    composer require 'composer/package-versions-deprecated'; \
    composer install --prefer-dist --no-progress --classmap-authoritative  --no-interaction; \
    composer update jikan-me/jikan; \
    chmod -R a+w storage/

COPY ./.env /home/jikanapi/app/.env
COPY s6/cont-init.d/00_bootstrap.sh /etc/cont-init.d/00_bootstrap.sh
COPY s6/cont-init.d/00_settimezone.sh /etc/cont-init.d/00_settimezone.sh
COPY s6/fix-attrs.d /etc/fix-attrs.d
COPY s6/services.d/jikan /etc/services.d/jikan
COPY s6/services.d/jikan-queue-1 /etc/services.d/jikan-queue-1
COPY s6/services.d/jikan-queue-2 /etc/services.d/jikan-queue-2
COPY s6/services.d/jikan-queue-3 /etc/services.d/jikan-queue-3
COPY .s6-svscan /var/run/s6/services/.s6-svscan

USER root
RUN set -ex; \
    chown jikanapi:jikanapi /home/jikanapi/app/.env; \
    find /etc/services.d/ -type f -print0 | xargs -0 dos2unix; \
    mkdir -p /var/log/s6-jikan-job-queue-1; \
    mkdir -p /var/log/s6-jikan-job-queue-2; \
    mkdir -p /var/log/s6-jikan-job-queue-3; \
	mkdir -p /var/log/s6-jikan;

ENTRYPOINT ["/init"]
