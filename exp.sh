#!/bin/bash

# Check 
echo '[+] Checking for nginx webdav support'
webdav=$(nginx -V 2>&1 | grep -o with-http_dav_module)
# if webdab is not empty, then it is compiled with webdav support
if [ $webdav ]; then
    echo '[+] Nginx is compiled with WebDAV support'
else
    echo '[!] Nginx is not compiled with WebDAV support'
    exit 1
fi

echo '[+] Creating config'

# Create the Nginx configuration file with the necessary directives to allow file upload with PUT requests
cat <<EOF >/tmp/nginx.conf
user root;
worker_processes auto; # Set to 'auto' for automatic detection of the number of processor cores
pid /run/nginx.pid;

events {
    worker_connections 1024; # Increase if you expect high load
}

http {
    include            /etc/nginx/mime.types;
    default_type       application/octet-stream;
    sendfile           on;
    keepalive_timeout  65;

    server {
        listen 2333;

        # Default server root directory (should be changed to a proper one)
        root /;

        # Enable directory listing
        autoindex on;

        # Enable PUT and DELETE methods for WebDAV
        dav_methods PUT DELETE MKCOL COPY MOVE;

        # Temporary path for storing client request bodies (needed for file uploads)
        client_body_temp_path /tmp/client_body;

        # Maximum allowed size of the client request body
        client_max_body_size 8M;

        location / {
            # Enable DAV
            dav_methods PUT DELETE MKCOL COPY MOVE;

            # Set the access permissions for the uploaded files
            dav_access user:rw group:rw all:r;

            # Allow all users to upload files
            allow all;

            # Enable automatic indexing of directories
            autoindex on;
        }
    }
}
EOF

echo '[+] Initializing nginx'
# Start Nginx with the new configuration
sudo /usr/sbin/nginx -c /tmp/nginx.conf
