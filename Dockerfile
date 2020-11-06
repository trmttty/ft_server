# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ttarumot <ttarumot@student.42tokyo.co.j    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2020/10/05 17:40:45 by ttarumot          #+#    #+#              #
#    Updated: 2020/10/05 18:09:54 by ttarumot         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# get image
FROM debian:buster

# install tools
RUN apt update && apt upgrade -y \
    && apt install -y nginx mariadb-server mariadb-client php-cgi php-common php-fpm php-pear \
        php-mbstring php-zip php-net-socket php-gd php-xml-util php-gettext php-mysql php-bcmath \
        wget vim

# set database
RUN service mysql start \
	&& mysql -e "CREATE DATABASE wpdb;" \
	&& mysql -e "CREATE USER 'wpuser'@'localhost' identified by 'dbpassword';" \
	&& mysql -e "GRANT ALL PRIVILEGES ON wpdb.* TO 'wpuser'@'localhost';" \
	&& mysql -e "FLUSH PRIVILEGES;" \
	&& mysql -e "EXIT"

# install wordpress
WORKDIR /tmp/
RUN wget https://ja.wordpress.org/latest-ja.tar.gz \
	&& tar -xvzf latest-ja.tar.gz \
	&& mv wordpress /var/www/html/

# install phpmyadmin
WORKDIR /tmp/
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz \
	&& tar -xvzf phpMyAdmin-5.0.2-all-languages.tar.gz \
	&& mv phpMyAdmin-5.0.2-all-languages phpmyadmin \
	&& mv phpmyadmin /var/www/html/

# install entrykit
WORKDIR /tmp/
RUN wget https://github.com/progrium/entrykit/releases/download/v0.4.0/entrykit_0.4.0_Linux_x86_64.tgz \
	&& tar -xvzf entrykit_0.4.0_Linux_x86_64.tgz \
	&& mv entrykit /bin/entrykit \
	&& entrykit --symlink

# set openssl
RUN	mkdir /etc/nginx/ssl \
	&& openssl genrsa -out /etc/nginx/ssl/private.key 2048 \
	&& openssl req -new -key /etc/nginx/ssl/private.key -out /etc/nginx/ssl/server.csr -subj "/C=JP/ST=Tokyo/L=Roppongi/O=42tokyo/OU=/CN=localhost" \
	&& openssl x509 -days 365 -req -signkey /etc/nginx/ssl/private.key -in /etc/nginx/ssl/server.csr -out /etc/nginx/ssl/server.crt

# copy config
COPY ./srcs/default.tmpl /etc/nginx/sites-available/
COPY ./srcs/php.ini /etc/php/7.3/fpm/php.ini
COPY ./srcs/wp-config.php /var/www/html/wordpress/
COPY ./srcs/start.sh /tmp/

WORKDIR /
ENTRYPOINT ["render", "/etc/nginx/sites-available/default", "--", "bash", "/tmp/start.sh"]
