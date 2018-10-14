#!/bin/bash -x
### Install guacamole:
### https://guacamole.apache.org/doc/gug/installing-guacamole.html

#set -e   # stop on error

source /host/settings.sh

main() {
    local release=0.9.14
    local mysql_pass=$(random_pass)

    install_server $release
    install_client $release
    install_mysql_auth $release $mysql_pass
    config_guacamole_properties $mysql_pass
    config_user_mapping

    setup_vnc
    setup_xrdp
    setup_apache
    #setup_nginx
    #ram_optimizations
}

random_pass() {
    local size=${1:-16}
    echo -n $(tr -cd '[:alnum:]' < /dev/urandom | fold -w$size | head -n1)
}

download() {
    local filename="$1"
    wget -q -O $(basename $filename) \
         'http://apache.org/dyn/closer.cgi?action=download&filename='$filename
}

get_server_code() {
    local release=$1

    if [[ $release == 'github' ]]; then
        # get the source code from github
        git clone git://github.com/apache/guacamole-server.git
        cd guacamole-server/
        autoreconf -fi
    else
        # download the source code of guacamole-server
        download guacamole/$release/source/guacamole-server-$release.tar.gz
        tar --file=guacamole-server-$release.tar.gz --gunzip --extract
        cd guacamole-server-$release/

        # get and apply a patch for guacamole-server-0.9.14
        if [[ $release == '0.9.14' ]]; then
            wget -O ./src/terminal/cd0e48234a079813664052b56c501e854753303a.patch \
                 https://github.com/apache/guacamole-server/commit/cd0e48234a079813664052b56c501e854753303a.patch
            patch ./src/terminal/typescript.c ./src/terminal/cd0e48234a079813664052b56c501e854753303a.patch
        fi
    fi
}

install_server() {
    local release=$1

    apt update
    local build_dependencies="
        build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev libossp-uuid-dev
        libavcodec-dev libavutil-dev libswscale-dev
        libfreerdp-dev libpango1.0-dev libssh2-1-dev libtelnet-dev
        libvncserver-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev
        gcc-6 dpkg-dev
    "
    apt install --yes $build_dependencies

    # get the source code of the server
    get_server_code $release

    # configure, make and install
    CC=gcc-6 ./configure --with-init-dir=/etc/init.d
    CC=gcc-6 make
    make install
    ldconfig

    # move files to correct locations
    local build_folder=$(dpkg-architecture -qDEB_BUILD_GNU_TYPE)
    mkdir -p /usr/lib/$build_folder/freerdp/
    ln -sf /usr/local/lib/freerdp/guac*.so /usr/lib/$build_folder/freerdp/

    # enable and start the service guacd
    systemctl enable guacd
    systemctl start guacd

    # cleanup
    cd ..
    rm -rf guacamole-server*
}

install_client() {
    local release=$1

    apt install --yes tomcat8

    if [[ $release != 'github' ]]; then
        download guacamole/$release/binary/guacamole-$release.war
        mv guacamole-*.war /var/lib/tomcat8/webapps/guacamole.war
    else
        apt install --yes maven
        git clone git://github.com/apache/guacamole-client.git
        cd guacamole-client/
        mvn package
        mv guacamole/target/guacamole*.war /var/lib/tomcat8/webapps/guacamole.war
        # cleanup
        cd ..
        rm -rf guacamole-client/
        apt remove --yes --purge --autoremove maven
    fi

    systemctl restart tomcat8
}

install_mysql_auth() {
    local release=$1
    local mysql_pass=$2
    local root_pass=$(random_pass)

    # install mysql
    cat <<EOF | debconf-set-selections
mysql-server mysql-server/root_password password $root_pass
mysql-server mysql-server/root_password_again password $root_pass
EOF
    apt install --yes \
        mysql-server mysql-client mysql-common mysql-utilities libmysql-java

    # link the mysql driver to the library
    mkdir -p /etc/guacamole/lib
    ln -sf /usr/share/java/mysql-connector-java.jar /etc/guacamole/lib/

    # create the database and user
    local mysql='mysql --defaults-file=/etc/mysql/debian.cnf'
    $mysql -e "
        DROP DATABASE IF EXISTS guacamole_db;
        CREATE DATABASE guacamole_db;
        DROP USER IF EXISTS 'guacamole_user'@'localhost';
        CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY '$mysql_pass';
        GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
        FLUSH PRIVILEGES;
    "

    # get the auth-jdbc extension
    rm -rf guacamole-auth-jdbc-*
    download guacamole/$release/binary/guacamole-auth-jdbc-$release.tar.gz
    tar --file=guacamole-auth-jdbc-$release.tar.gz --gunzip --extract

    # install the auth-jdbc extension
    mkdir -p /etc/guacamole/extensions/
    cp guacamole-auth-jdbc-*/mysql/guacamole-auth-jdbc-mysql-*.jar \
       /etc/guacamole/extensions/

    # create the db tables
    cat guacamole-auth-jdbc-*/mysql/schema/*.sql | $mysql guacamole_db

    # change the default password of guacadmin
    [[ -n $GUAC_PASS ]] && $mysql guacamole_db -e "
        SET @salt = UNHEX(SHA2(UUID(), 256));
        UPDATE guacamole_user
        SET username = '$GUAC_ADMIN',
            password_hash = UNHEX(SHA2(CONCAT('$GUAC_PASS', HEX(@salt)), 256)),
            password_salt = @salt
        WHERE user_id = 1;
        "

    # cleanup
    rm -rf guacamole-auth-jdbc-*

    # return $mysql_pass
    echo $mysql_pass
}

config_guacamole_properties() {
    local mysql_pass=$1

    mkdir -p /etc/guacamole
    cat <<EOF > /etc/guacamole/guacamole.properties
guacd-hostname: localhost
guacd-port:     4822

mysql-hostname: localhost
mysql-port:     3306
mysql-database: guacamole_db
mysql-username: guacamole_user
mysql-password: $mysql_pass

auth-provider:  net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
user-mapping:   /etc/guacamole/user-mapping.xml
EOF

    # link to tomcat libraries
    ln -sf /etc/guacamole/guacamole.properties \
       /usr/share/tomcat8/lib/guacamole.properties

    systemctl restart tomcat8
}

config_user_mapping() {
    cat <<EOF > /etc/guacamole/user-mapping.xml
<user-mapping>
    <authorize username="" password="">
        <connection name="VNC">
            <protocol>vnc</protocol>
            <param name="hostname">127.0.0.1</param>
            <param name="port">5901</param>
            <param name="enable-audio">true</param>
        </connection>
        <connection name="RDP">
            <protocol>rdp</protocol>
            <param name="hostname">127.0.0.1</param>
            <param name="enable-audio-input">true</param>
            <param name="enable-printing">true</param>
        </connection>
        <connection name="SSH">
            <protocol>ssh</protocol>
            <param name="hostname">127.0.0.1</param>
            <param name="enable-sftp">true</param>
            <param name="font-name">Monaco</param>
        </connection>
    </authorize>
</user-mapping>
EOF
    # fix permissions and ownership
    chmod 600 /etc/guacamole/user-mapping.xml
    chown tomcat8:tomcat8 /etc/guacamole/user-mapping.xml

    install_font_monaco
}

install_font_monaco() {
    local font_dir=/usr/share/fonts/truetype/Monaco
    [[ -d $font_dir ]] && return

    mkdir -p $font_dir
    cd $font_dir
    wget http://www.gringod.com/wp-upload/software/Fonts/Monaco_Linux.ttf
    fc-cache -f .
    cd -
}

setup_vnc() {
    apt install --yes vnc4server

    # set vnc password
    if [[ -z $VNC_PASS ]]; then
	vnc_command='Xvnc -SecurityTypes None'
    else
	echo "$VNC_PASS" | vncpasswd -f >> /etc/vncpasswd
	chmod 600 /etc/vncpasswd
	vnc_command='Xvnc -SecurityTypes VncAuth -PasswordFile /etc/vncpasswd'
    fi

    # enable remote display and VNC server
    cat <<EOF > /etc/lightdm/lightdm.conf.d/20-vnc.conf
[XDMCPServer]
enabled=true

[VNCServer]
enabled=true
command=$vnc_command
port=${VNC_PORT:-5901}
width=${VNC_WIDTH:-1024}
height=${VNC_HEIGHT:-768}
depth=${VNC_DEPTH:-24}
EOF
    systemctl restart lightdm

    # start noVNC service
    cat <<EOF > /etc/systemd/system/websockify.service
[Unit]
Description = start noVNC service
After = syslog.target network.target

[Service]
ExecStart = /usr/bin/websockify --web=/usr/share/novnc/ ${WS_PORT:-6901} localhost:${VNC_PORT:-5901}

[Install]
WantedBy = graphical.target
EOF
    systemctl enable websockify.service
    systemctl start websockify.service
    # open vnc.html by default
    ln -s /usr/share/novnc/{vnc,index}.html
}

setup_xrdp() {
    apt install --yes \
        xrdp xorgxrdp xrdp-pulseaudio-installer
    sed -i /etc/xrdp/xrdp.ini \
        -e '/^\[console\]/,$ s/^/# /' \
        -e '/^\[X11rdp\]/,+8 s/^/# /'

    install_pulseaudio_module_xrdp

    systemctl restart xrdp
}

# install pulseaudio-module-xrdp
# https://github.com/neutrinolabs/pulseaudio-module-xrdp/wiki/README
install_pulseaudio_module_xrdp() {
    # make sure that we have the needed tools
    apt install --yes pulseaudio build-essential dpkg-dev git

    # get the source of pulseaudio
    cat <<EOF > /etc/apt/sources.list.d/bionic-updates-src.list
deb-src http://archive.ubuntu.com/ubuntu bionic-updates main restricted universe multiverse
EOF
    apt update
    apt source pulseaudio

    # build the pulseaudio package
    apt build-dep --yes pulseaudio
    cd pulseaudio-11.1
    ./configure
    cd ..

    # build xrdp source / sink modules
    git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
    cd pulseaudio-module-xrdp
    ./bootstrap && ./configure PULSE_DIR=$(dirname $(pwd))/pulseaudio-11.1
    make
    make install
    cd ..

    # cleanup
    rm -rf pulseaudio*
    rm /usr/lib/pulse-11.1/modules/*.la
    rm /etc/apt/sources.list.d/bionic-updates-src.list
}

setup_apache() {
    apt install --yes apache2

    cat <<EOF > /etc/apache2/conf-available/guacamole.conf
<Location /guac/>
    Order allow,deny
    Allow from all
    ProxyPass http://localhost:8080/guacamole/ flushpackets=on
    ProxyPassReverse http://localhost:8080/guacamole/
    ProxyPassReverseCookiePath /guacamole/ /guac/
</Location>

<Location /guac/websocket-tunnel>
    Order allow,deny
    Allow from all
    ProxyPass ws://localhost:8080/guacamole/websocket-tunnel
    ProxyPassReverse ws://localhost:8080/guacamole/websocket-tunnel
</Location>

SetEnvIf Request_URI "^/guac/tunnel" dontlog
CustomLog  /var/log/apache2/guac.log common env=!dontlog
EOF

    local port=${WS_PORT:-6901}
    cat <<EOF > /etc/apache2/conf-available/webvnc.conf
<Location /vnc/>
    Order allow,deny
    Allow from all
    ProxyPass http://127.0.0.1:$port/ flushpackets=on
    ProxyPassReverse http://127.0.0.1:$port/
    ProxyPassReverseCookiePath / /vnc/
</Location>

<Location /websockify>
    Order allow,deny
    Allow from all
    ProxyPass ws://127.0.0.1:$port/websockify retry=3
    ProxyPassReverse ws://127.0.0.1:$port/websockify
</Location>
EOF
    
    a2enmod ssl proxy proxy_http proxy_wstunnel
    a2ensite default-ssl.conf
    a2enconf guacamole.conf webvnc.conf

    # we need to refer to this apache2 config by the name "$DOMAIN.conf" as well
    ln /etc/apache2/sites-available/{default-ssl,$DOMAIN}.conf


    systemctl restart apache2
}

setup_nginx() {
    apt install --yes nginx

    cat <<'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    include snippets/snakeoil.conf;

    root /var/www/html;
    index index.html index.htm;
    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    location /guac/ {
        proxy_pass http://localhost:8080/guacamole/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;
        proxy_cookie_path /guacamole/ /guac/;
        access_log off;
    }
}
EOF

    systemctl restart nginx
}

ram_optimizations() {

    # apache2 small ram configuration
    cat <<EOF > /etc/apache2/mods-available/mpm_event.conf
<IfModule mpm_event_module>
    StartServers              1
    MinSpareThreads          13
    MaxSpareThreads          45
    ThreadLimit              32
    ThreadsPerChild          13
    MaxRequestWorkers        80
    MaxConnectionsPerChild    0
</IfModule>
EOF
    systemctl restart apache2

    # mysql small ram configuration
    cat <<EOF > /etc/mysql/mysql.conf.d/mysqld-small.cnf
[mysqld]
performance_schema = off

innodb_buffer_pool_size=5M
innodb_log_buffer_size=256K
query_cache_size=0
max_connections=10
key_buffer_size=8
thread_cache_size=0
host_cache_size=0
innodb_ft_cache_size=1600000
innodb_ft_total_cache_size=32000000

# per thread or per operation settings
thread_stack=131072
sort_buffer_size=32K
read_buffer_size=8200
read_rnd_buffer_size=8200
max_heap_table_size=16K
tmp_table_size=1K
bulk_insert_buffer_size=0
join_buffer_size=128
net_buffer_length=1K
innodb_sort_buffer_size=64K

#settings that relate to the binary log (if enabled)
binlog_cache_size=4K
binlog_stmt_cache_size=4K
EOF
    systemctl restart mysql

    # tomcat
    sed -i /etc/default/tomcat8 \
        -e '/^JAVA_OPTS/ a JAVA_OPTS="${JAVA_OPTS} -Xmx20m -Xms20m"'
    systemctl restart tomcat8
}

# call the main function
main
