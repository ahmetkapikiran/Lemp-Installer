#!/bin/sh
#Author : Ahmet KAPIKIRAN
#Author link : http://www.ahmetkapikiran.com/nginx-php-fpm-mysql-kurulum-scripti/
#Support link: http://www.ahmetkapikiran.com/nginx-php-fpm-mysql-kurulum-scripti/
echo "Nginx Kuruluyor"
sleep 2
rpm -Uvh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
yum -y install nginx
service stop nginx

clear
echo "Php-fpm Kuruluyor"
sleep 2
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum -y install php-fpm perl
service stop php-fpm

clear
echo "Mysql Kuruluyor"
sleep 2
yum -y install php-mysql mysql-server
clear
echo "Domain Giriniz(Dikkat edin example.com gibi olacak): "
read your_domain
echo "Seçtiğiniz Domain: $your_domain"
echo "Kullanıcı ve web dizini oluşturuluyor"
adduser -d /home/${your_domain} -s /sbin/nologin ${your_domain}
mkdir -p /home/${your_domain}/www
chown -R ${your_domain}:${your_domain} /home/${your_domain}

clear
echo "Nginx Conf Düzenleniyor"
sleep 2
find /etc/nginx -name 'nginx.conf' | xargs perl -pi -e 's/http {/http {\nserver_names_hash_bucket_size  64;/g'
nginx -t
rm -rf /etc/nginx/conf.d/default.conf
ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
echo -e "server {
    listen       $ip:80;
    server_name  $your_domain www.$your_domain;
    root         /home/$your_domain/www/;
    index        index.html index.php;
    error_log    /var/log/nginx/$your_domain.error.log error;
    access_log   off;
    log_not_found     off;
    
    location / {
      try_files $uri $uri/ /index.php;
    }
    
    location ~ \.php$ {
    
        fastcgi_pass   unix:/var/run/php-fpm/$your_domain.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }

    location ~ /\.ht {
        deny  all;
    }
}" >> /etc/nginx/conf.d/${your_domain}.conf

clear
echo "Php-fpm Konfigresi yapılıyor."
echo -e "[$your_domain]
listen = /var/run/php-fpm/$your_domain.sock
user = $your_domain
group = $your_domain
pm = dynamic
pm.max_children = 25
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 25
pm.max_requests = 0
php_admin_value[error_log] = /var/log/php-fpm/$your_domain.error.log
php_admin_value[log_errors] = on
php_flag[display_errors] = on
php_admin_value[open_basedir] = /home/$your_domain
php_admin_value[upload_tmp_dir] = /home/$your_domain/
php_admin_value[sesssion.save_path] = /var/lib/php/session/
chdir = /" >> /etc/php-fpm.d/${your_domain}.conf
#Session klasörü oluştur
mkdir -p /var/lib/php/session/
chown ${your_domain}:${your_domain} /var/lib/php/session/

#clear default conf
rm -rf /etc/php-fpm.d/www.conf
rm -rf /etc/nginx/conf.d/example_ssl.conf

clear
echo "Kurulum başarıyla tamamlanmıştır. Virtual conflarınız nginx ve php-fpm tanımlanmıştır.
Destek için http://www.ahmetkapikiran.com/nginx-php-fpm-mysql-kurulum-scripti/"