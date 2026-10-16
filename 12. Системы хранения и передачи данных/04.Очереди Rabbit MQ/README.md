# 12.04 Очереди Rabbit MQ

----------------------------------------------------------------------------------------------------------------
В ходе выполнения задания были использованы такие конфигурационные файлы:

[docker-compose.yml](Files/docker-compose.yml)

[docker-compose-cluster.yml](Files/docker-compose-cluster.yml)

[docker-compose-scripts.yml](Files/docker-compose-scripts.yml)

[Dockerfile](Files/scripts/Dockerfile)

[producer.py](Files/scripts/producer.py)

[requirements.txt](Files/scripts/requirements.txt)


## Задание 1. Установка RabbitMQ

Используя Vagrant или VirtualBox, создайте виртуальную машину и установите *RabbitMQ*. Добавьте *management plug-in* и зайдите в веб-интерфейс.

Итогом выполнения домашнего задания будет приложенный скриншот веб-интерфейса *RabbitMQ*.

## Ответ:

![alt text](<Screenshots/Задание 1-1.png>)

![alt text](<Screenshots/Задание 1-2.png>)

![alt text](<Screenshots/Задание 1-3.png>)

![alt text](<Screenshots/Задание 1-4.png>)


----------------------------------------------------------------------------------------------------------------

## Задание 2. Отправка и получение сообщений

Используя приложенные скрипты, проведите тестовую отправку и получение сообщения. Для отправки сообщений необходимо запустить скрипт *producer.py*.

Для работы скриптов вам необходимо установить *Python версии 3* и библиотеку *Pika*. Также в скриптах нужно указать IP-адрес машины, на которой запущен *RabbitMQ*, заменив *localhost* на нужный *IP*.

```

$ pip install pika

```

Зайдите в веб-интерфейс, найдите очередь под названием *hello* и сделайте скриншот. После чего запустите второй скрипт *consumer.py* и сделайте скриншот результата выполнения скрипта

В качестве решения домашнего задания приложите оба скриншота, сделанных на этапе выполнения.

Для закрепления материала можете попробовать модифицировать скрипты, чтобы поменять название очереди и отправляемое сообщение.

## Ответ:

![alt text](<Screenshots/Задание 2-1.png>)

![alt text](<Screenshots/Задание 2-2.png>)

![alt text](<Screenshots/Задание 2-3.png>)

![alt text](<Screenshots/Задание 2-4.png>)

![alt text](<Screenshots/Задание 2-5.png>)

![alt text](<Screenshots/Задание 2-6.png>)

![alt text](<Screenshots/Задание 2-7.png>)

![alt text](<Screenshots/Задание 2-8.png>)

![alt text](<Screenshots/Задание 2-9.png>)

![alt text](<Screenshots/Задание 2-10.png>)

![alt text](<Screenshots/Задание 2-11.png>)

![alt text](<Screenshots/Задание 2-12.png>)

![alt text](<Screenshots/Задание 2-13.png>)

![alt text](<Screenshots/Задание 2-14.png>)

![alt text](<Screenshots/Задание 2-15.png>)

![alt text](<Screenshots/Задание 2-16.png>)

![alt text](<Screenshots/Задание 2-17.png>)

![alt text](<Screenshots/Задание 2-18.png>)

![alt text](<Screenshots/Задание 2-19.png>)

![alt text](<Screenshots/Задание 2-20.png>)

![alt text](<Screenshots/Задание 2-21.png>)

![alt text](<Screenshots/Задание 2-22.png>)

![alt text](<Screenshots/Задание 2-23.png>)

![alt text](<Screenshots/Задание 2-24.png>)

![alt text](<Screenshots/Задание 2-25.png>)

![alt text](<Screenshots/Задание 2-26.png>)

![alt text](<Screenshots/Задание 2-27.png>)

----------------------------------------------------------------------------------------------------------------

## Задание 3. Подготовка HA кластера

Используя *Vagrant* или *VirtualBox*, создайте вторую виртуальную машину и установите *RabbitMQ*. Добавьте в файл *hosts* название и IP-адрес каждой машины, чтобы машины могли видеть друг друга по имени.

Пример содержимого *hosts* файла:

```

$ cat /etc/hosts
192.168.0.10 rmq01
192.168.0.11 rmq02

```

После этого ваши машины могут пинговаться по имени.

Затем объедините две машины в кластер и создайте политику *ha-all* на все очереди.

В качестве решения домашнего задания приложите скриншоты из веб-интерфейса с информацией о доступных нодах в кластере и включённой политикой.

Также приложите вывод команды с двух нод:

*$ rabbitmqctl cluster_status*
Для закрепления материала снова запустите скрипт *producer.py* и приложите скриншот выполнения команды на каждой из нод:

```

$ rabbitmqadmin get queue='hello'

```

После чего попробуйте отключить одну из нод, желательно ту, к которой подключались из скрипта, затем поправьте параметры подключения в скрипте *consumer.py* на вторую ноду и запустите его.

Приложите скриншот результата работы второго скрипта.

## Ответ:

![alt text](<Screenshots/Задание 3-1.png>)

![alt text](<Screenshots/Задание 3-2.png>)

![alt text](<Screenshots/Задание 3-3.png>)

![alt text](<Screenshots/Задание 3-4.png>)

![alt text](<Screenshots/Задание 3-5.png>)

![alt text](<Screenshots/Задание 3-6.png>)

![alt text](<Screenshots/Задание 3-7.png>)

![alt text](<Screenshots/Задание 3-8.png>)

![alt text](<Screenshots/Задание 3-9.png>)

![alt text](<Screenshots/Задание 3-10.png>)

![alt text](<Screenshots/Задание 3-11.png>)

![alt text](<Screenshots/Задание 3-12.png>)

![alt text](<Screenshots/Задание 3-13.png>)

![alt text](<Screenshots/Задание 3-14.png>)

![alt text](<Screenshots/Задание 3-15.png>)

![alt text](<Screenshots/Задание 3-16.png>)

![alt text](<Screenshots/Задание 3-17.png>)

![alt text](<Screenshots/Задание 3-18.png>)

![alt text](<Screenshots/Задание 3-19.png>)

![alt text](<Screenshots/Задание 3-20.png>)

![alt text](<Screenshots/Задание 3-21.png>)

![alt text](<Screenshots/Задание 3-22.png>)

![alt text](<Screenshots/Задание 3-23.png>)

![alt text](<Screenshots/Задание 3-24.png>)

----------------------------------------------------------------------------------------------------------------

## Задание 4. Ansible playbook

Напишите плейбук, который будет производить установку *RabbitMQ* на любое количество нод и объединять их в кластер. При этом будет автоматически создавать политику *ha-all*.

Готовый плейбук разместите в своём репозитории.

## Ответ: 