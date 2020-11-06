service mysql start
service php7.3-fpm stop
service php7.3-fpm start
service nginx start
tail -f /var/log/nginx/access.log