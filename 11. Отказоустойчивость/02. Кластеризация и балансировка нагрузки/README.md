# 11.02 Кластеризация и балансировка нагрузки

----------------------------------------------------------------------------------------------------------------

## Задание 1

- Запустите два *simple python* сервера на своей виртуальной машине на разных портах
- Установите и настройте *HAProxy*, воспользуйтесь материалами к лекции по ссылке
- Настройте балансировку Round-robin на 4 уровне.
- На проверку направьте конфигурационный файл *haproxy*, скриншоты, где видно перенаправление запросов на разные серверы при обращении к HAProxy.

## Решение:

[Конфигурационный файл haproxy: haproxy-1.cfg](Files/haproxy-1.cfg)

```

isten stats  # веб-страница со статистикой
        bind                    :888
        mode                    http
        stats                   enable
        stats uri               /stats
        stats refresh           5s
        stats realm             Haproxy\ Statistics

frontend example  # секция фронтенд
        mode http
        bind :8088
        default_backend web_servers

backend web_servers    # секция бэкенд
        mode http
        balance roundrobin
        option httpchk
        http-check send meth GET uri /index.html
        server s1 127.0.0.1:8888 check
        server s2 127.0.0.1:9999 check

listen web_tcp

	bind :1325

	server s1 127.0.0.1:8888 check inter 3s
	server s2 127.0.0.1:9999 check inter 3s

```

[Конфигурационный файл: http1](Files/http1)

[Конфигурационный файл: http2](Files/http2)

![alt text](<Screenshots/Задание 1-1.png>)

![alt text](<Screenshots/Задание 1-2.png>)

----------------------------------------------------------------------------------------------------------------

## Задание 2

- Запустите три *simple python* сервера на своей виртуальной машине на разных портах
- Настройте балансировку *Weighted Round Robin* на 7 уровне, чтобы первый сервер имел вес 2, второй - 3, а третий - 4
- *HAproxy* должен балансировать только тот *http-трафик*, который адресован домену *example.local*
- На проверку направьте конфигурационный файл haproxy, скриншоты, где видно перенаправление запросов на разные серверы при обращении к HAProxy c использованием домена *example.local* и без него.

## Решение:

[Конфигурационный файл haproxy: haproxy-2.cfg](Files/haproxy-2.cfg)

```

listen stats  # веб-страница со статистикой
        bind                    :888
        mode                    http
        stats                   enable
        stats uri               /stats
        stats refresh           5s
        stats realm             Haproxy\ Statistics

frontend example  # секция фронтенд
        mode http
        bind :8088
	acl ACL_example.local hdr(host) -i example.local
	use_backend web_servers if ACL_example.local

backend web_servers    # секция бэкенд
        mode http
        balance roundrobin
        option httpchk
        http-check send meth GET uri /index.html
        server s1 127.0.0.1:8888 weight 2 check
        server s2 127.0.0.1:9999 weight 3 check
	    server s3 127.0.0.1:5555 weight 4 check

```

[Конфигурационный файл: http1](Files/http1)

[Конфигурационный файл: http2](Files/http2)

[Конфигурационный файл: http3](Files/http3)

![alt text](<Screenshots/Задание 2-1.png>)

![alt text](<Screenshots/Задание 2-2.png>)

![alt text](<Screenshots/Задание 2-3.png>)

----------------------------------------------------------------------------------------------------------------

## Задание 3

- Настройте связку HAProxy + Nginx как было показано на лекции.
- Настройте Nginx так, чтобы файлы .jpg выдавались самим Nginx (предварительно разместите несколько тестовых картинок в директории /var/www/), а остальные запросы переадресовывались на HAProxy, который в свою очередь переадресовывал их на два Simple Python server.
- На проверку направьте конфигурационные файлы nginx, HAProxy, скриншоты с запросами jpg картинок и других файлов на Simple Python Server, демонстрирующие корректную настройку.

## Решение:

[Конфигурационный файл haproxy: haproxy-3.cfg](Files/haproxy-3.cfg)


```

listen stats  # веб-страница со статистикой
        bind                    :888
        mode                    http
        stats                   enable
        stats uri               /stats
        stats refresh           5s
        stats realm             Haproxy\ Statistics

listen web_tcp

	bind :1325

	server s1 127.0.0.1:8888 check inter 3s
	server s2 127.0.0.1:9999 check inter 3s

 ```

[Конфигурационный файл: example-http.conf](Files/example-http.conf)

```

server {
    listen 80;
    server_name example-http.com _;

    access_log /var/log/nginx/example-http.com-access.log combined;
    error_log  /var/log/nginx/example-http.com-error.log;

    location ~* \.(jpg|jpeg)$ {
        root /var/www;
        try_files $uri =404;
        access_log /var/log/nginx/jpg-access.log;
    }

    location / {
        proxy_pass http://127.0.0.1:1325;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

 ```
 
![alt text](<Screenshots/Задание 3-1.png>)

![alt text](<Screenshots/Задание 3-2.png>)

![alt text](<Screenshots/Задание 3-3.png>)

![alt text](<Screenshots/Задание 3-4.png>)

----------------------------------------------------------------------------------------------------------------
