map $http_accept $webp_suffix {
	default   "";
	"~*webp"  ".webp";
}
map $uri $filepath {
	"~^\/_pr?\/(.+)$"  $1;
}

server {
	listen		0.0.0.0:80;

#	server_name	pastvu.com www.pastvu.com;

	limit_conn	gulag 200;

	#redirect
	set $https_redirect 0;
	if ($host ~ '^www\.') { set $https_redirect 1; }
	if ($https_redirect = 1) {
		return 301 https://pastvu.com$request_uri;
	}

	root /public;

	charset         utf-8;
	etag            off;

#	access_log   /var/log/nginx/www.pastvu.com-acc  main;
	access_log   off;
	error_log    /var/log/nginx/www.pastvu.com-err  crit;


	include /etc/nginx/mime.types;
	include /etc/nginx/bad_user_agent;

	location = /robots.txt {
		allow all;
		log_not_found off;
		access_log off;
	}

	location  /.well-known/ {
		root /var/www/www.pastvu.com;
	}

	location  /. {
		return 404;
	}

	location ~* (favicon\.ico)$ {
		allow all;
		log_not_found off;
	}

	location ~* ^/sitemap\d*.xml(.gz)?$ {
		root /sitemap;
		allow all;

		try_files $uri  =404;
	}

	# Serve public photo's file. If File is not found, try to get protected version from backend
	location ~* ^\/_p\/([\/a-z0-9]+\.(?:jpe?g|png))$ {
		root /store;
		add_header Vary Accept;

		set $path     /public/photos/$1;

		expires        21600;
		aio            on;
		directio 512;
		output_buffers 1 8m;

		try_files $path$webp_suffix $path $uri/ @download_proxy;
	}

	# This location will be used for direct protected file request, always serves from backend
	location ~* ^\/_pr\/([\/a-z0-9]+\.(?:jpe?g|png))$ {
		try_files $uri @download_proxy;
	}

	# This location will be used if downloader backend returned ok (303) for /_pr/ request
	location @prOk {
		root /store;
 
		set $path     /protected/photos/$filepath;

		expires        21600;
		aio            on;
		directio 512;
		output_buffers 1 8m;
		try_files $path$webp_suffix $path $uri/ @prFailed;
	}

	# This location will be used if downloader backend didn't returned ok for /_pr/ request, or unavailable
	# It will rewrite uri to use /_prn/ location
	location @prFailed {
		rewrite ^\/_pr?\/(.+)$ /_prn/$1 last;
		return 404;
	}

	# This location will be used for direct covered file request of if pubic/protected serving failed
	location ~* ^\/_prn\/([\/a-z0-9]+\.(?:jpe?g|png))$ {
		root /store;
		add_header Vary Accept;

		set $path     /publicCovered/photos/$1;

		expires                  21600;
		aio            on;
		directio 512;
		output_buffers 1 8m;

		try_files $path$webp_suffix $path =404;
	}

	location ~* ^/(js|img|style|tpl)/ {
		set $country_code en;
		set $lang_code en;

		if ($http_accept_language ~* '^(.+?)[-,;]') {
			set $country_code $1;
		}
		if ($http_cookie ~* "past.lang=([^;][^ ]+)(?:;|$)") {
			set $country_code $1;
		}
		if ($country_code = ru) {
			set $lang_code ru;
		}

		root /public;

		aio            on;
		directio 512;
		output_buffers 1 8m;

		try_files $uri  =404;
	}

	location ^~ /_a/d/ {
		root /store/public/avatars;
		add_header Vary Accept;

		aio            on;
		directio 512;
		output_buffers 1 8m;

		try_files $uri$webp_suffix $uri /d/avatar.png =404;
	}

	location ^~ /_a/h/ {
		root /store/public/avatars;
		add_header Vary Accept;

		aio            on;
		directio 512;
		output_buffers 1 8m;

		try_files $uri$webp_suffix $uri /h/avatarth.png  =404;
	}

	location ^~ /files/ {
		root /store/public;
		allow all;

		try_files $uri  =404;
	}


	location / {
		set $country_code en;
		set $lang_code en;

		error_page  404  /views/html/status/404.html;

		try_files $uri @proxy;
	}


	location = /upload {
		error_page  404  /views/html/status/404.html;

		try_files $uri @upload_proxy;
	}


	location ^~ /download/ {
		error_page  404  /views/html/status/404.html;

		try_files $uri @download_proxy;
	}

	location = /uploadava {
		error_page  404  /views/html/status/404.html;

		try_files $uri @upload_proxy;
	}

	location = /speedtest {
		try_files $uri @speedtest_proxy;
	}

	location @proxy {
		proxy_next_upstream error timeout http_500 http_502 http_503 http_504;

		# The off parameter cancels the effect of all proxy_redirect directives on the current level
		proxy_redirect off;

		proxy_set_header   X-Real-IP           $remote_addr;
		proxy_set_header   X-Forwarded-For     $remote_addr; #$proxy_add_x_forwarded_for;
		proxy_set_header   X-Forwarded-Proto   $scheme;
		proxy_set_header   Host                $http_host;
		proxy_set_header   X-NginX-Proxy       true;

		proxy_http_version 1.1;
		proxy_set_header   Upgrade             $http_upgrade;
		proxy_set_header   Connection          $connection_upgrade;

		proxy_read_timeout 3m;
		proxy_send_timeout 3m;

		set $country_code en;
		set $lang_code en;

		if ($http_accept_language ~* '^(.+?)[-,;]') {
			set $country_code $1;
		}
		if ($http_cookie ~* "past.lang=([^;][^ ]+)(?:;|$)") {
			set $country_code $1;
		}
		if ($country_code = ru) {
			set $lang_code ru;
		}

		proxy_pass http://backend_nodejs_$lang_code;
	}

	location @upload_proxy {
		proxy_next_upstream error timeout http_500 http_502 http_503 http_504;

		proxy_redirect off;
		proxy_set_header   X-Real-IP           $remote_addr;
		proxy_set_header   X-Forwarded-For     $remote_addr; #$proxy_add_x_forwarded_for;
		proxy_set_header   X-Forwarded-Proto   $scheme;
		proxy_set_header   Host                $http_host;
		proxy_set_header   X-NginX-Proxy       true;

		proxy_http_version 1.1;
		proxy_set_header   Upgrade             $http_upgrade;
		proxy_set_header   Connection          $connection_upgrade;

		proxy_read_timeout 3m;
		proxy_send_timeout 3m;

		proxy_pass http://backend_upload_nodejs;
	}

	location @download_proxy {
		proxy_next_upstream error timeout http_500 http_502 http_503 http_504;

		# The off parameter cancels the effect of all proxy_redirect directives on the current level
		proxy_redirect off;
		# Look at the status codes returned from control server, for error_page
		proxy_intercept_errors on;

		proxy_set_header   X-Real-IP           $remote_addr;
		proxy_set_header   X-Forwarded-For     $remote_addr; #$proxy_add_x_forwarded_for;
		proxy_set_header   X-Forwarded-Proto   $scheme;
		proxy_set_header   Host                $http_host;
		proxy_set_header   X-NginX-Proxy       true;

		proxy_http_version 1.1;

		proxy_read_timeout 3m;
		proxy_send_timeout 3m;

		proxy_pass http://backend_download_nodejs;
		error_page 303 = @prOk;
		error_page 400 403 404 500 502 503 504 = @prFailed;
	}

	location @speedtest_proxy {
		proxy_next_upstream error timeout http_500 http_502 http_503 http_504;

		proxy_redirect off;
		proxy_set_header   X-Real-IP           $remote_addr;
		proxy_set_header   X-Forwarded-For     $remote_addr; #$proxy_add_x_forwarded_for;
		proxy_set_header   X-Forwarded-Proto   $scheme;
		proxy_set_header   Host                $http_host;
		proxy_set_header   X-NginX-Proxy       true;

		proxy_http_version 1.1;
		proxy_set_header   Upgrade             $http_upgrade;
		proxy_set_header   Connection          $connection_upgrade;

		proxy_pass http://backend_speedtest_nodejs;
	}
}
