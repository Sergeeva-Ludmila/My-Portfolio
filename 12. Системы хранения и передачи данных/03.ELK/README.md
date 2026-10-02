# 11.3 ELK

----------------------------------------------------------------------------------------------------------------

Для выполнения всех заданий была создана директория и в ней файлы конфигурации, а так же создан и запущен docker-compose.yml.Файлы конфигурации прикреплены каждый к своему заданию.

Получилась такая структура проекта:

![alt text](<Screenshots/Структурв проекта.png>)


## Задание 1. Elasticsearch

1. Установите и запустите *Elasticsearch*, после чего поменяйте параметр *cluster_name* на случайный.
2. Приведите скриншот команды *'curl -X GET 'localhost:9200/_cluster/health?pretty'*, сделанной на сервере с установленным *Elasticsearch*. Где будет виден нестандартный *cluster_name*.

## Ответ:

[elasticsearch.yml](Files/elasticsearch/elasticsearch.yml)

![alt text](<Screenshots/Задание 1-1.png>)

![alt text](<Screenshots/Задание 1-2.png>)


----------------------------------------------------------------------------------------------------------------

## Задание 2. Kibana

1. Установите и запустите *Kibana*.
2. Приведите скриншот интерфейса *Kibana* на странице *http://<ip вашего сервера>:5601/app/dev_tools#/console*, где будет выполнен запрос *GET /_cluster/health?pretty*.

## Ответ:

[kibana.yml](Files/kibana/kibana.yml)

![alt text](<Screenshots/Задание 2-1.png>)

![alt text](<Screenshots/Задание 2-2.png>)

![alt text](<Screenshots/Задание 2-3.png>)


----------------------------------------------------------------------------------------------------------------

## Задание 3. Logstash

1. Установите и запустите *Logstash* и *Nginx*. С помощью *Logstash* отправьте *access-лог Nginx в Elasticsearch*.
2. Приведите скриншот интерфейса *Kibana*, на котором видны логи *Nginx*.

## Ответ:

[logstash.yml](Files/logstash/config/logstash.yml)

[pipeline/nginx.conf](Files/logstash/pipeline/nginx.conf)

[nginx.conf](Files/nginx/nginx.conf)

![alt text](<Screenshots/Задание 3-1.png>)

![alt text](<Screenshots/Задание 3-2.png>)

![alt text](<Screenshots/Задание 3-3.png>)

![alt text](<Screenshots/Задание 3-4.png>)

![alt text](<Screenshots/Задание 3-5.png>)

![alt text](<Screenshots/Задание 3-6.png>)

![alt text](<Screenshots/Задание 3-7.png>)

![alt text](<Screenshots/Задание 3-8.png>)

![alt text](<Screenshots/Задание 3-9.png>)

----------------------------------------------------------------------------------------------------------------

## Задание 4. Filebeat.

1. Установите и запустите *Filebeat*. Переключите поставку логов *Nginx с Logstash на Filebeat*.
2. Приведите скриншот интерфейса *Kibana*, на котором видны логи *Nginx*, которые были отправлены через *Filebeat*.

## Ответ:

[filebeat.yml](Files/filebeat/filebeat.yml)

![alt text](<Screenshots/Задание 4-1.png>)

![alt text](<Screenshots/Задание 4-2.png>)

![alt text](<Screenshots/Задание 4-3.png>)

![alt text](<Screenshots/Задание 4-4.png>)

![alt text](<Screenshots/Задание 4-5.png>)

![alt text](<Screenshots/Задание 4-6.png>)


----------------------------------------------------------------------------------------------------------------