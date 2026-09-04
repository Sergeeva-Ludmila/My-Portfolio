# 11.04 Отказоустойчивость в облаке

----------------------------------------------------------------------------------------------------------------

## Задание 1

Возьмите за основу решение к заданию 1 из занятия *«Подъём инфраструктуры в Яндекс Облаке»*.

1. Теперь вместо одной виртуальной машины сделайте *terraform playbook*, который:
- создаст 2 идентичные виртуальные машины. Используйте аргумент count для создания таких ресурсов;
- создаст таргет-группу. Поместите в неё созданные на шаге 1 виртуальные машины;
- создаст сетевой балансировщик нагрузки, который слушает на порту 80, отправляет трафик на порт 80 виртуальных машин и *http healthcheck* на порт 80 виртуальных машин.

Рекомендуем изучить документацию сетевого балансировщика нагрузки для того, чтобы было понятно, что вы сделали.

2. Установите на созданные виртуальные машины пакет Nginx любым удобным способом и запустите Nginx веб-сервер на порту 80.
3. Перейдите в веб-консоль *Yandex Cloud* и убедитесь, что:
- созданный балансировщик находится в статусе *Active*,
- обе виртуальные машины в целевой группе находятся в состоянии *healthy*.
4. Сделайте запрос на 80 порт на внешний IP-адрес балансировщика и убедитесь, что вы получаете ответ в виде дефолтной страницы *Nginx*.

В качестве результата пришлите:

1. Terraform Playbook.
2. Скриншот статуса балансировщика и целевой группы.
3. Скриншот страницы, которая открылась при запросе IP-адреса балансировщика.

## Решение:

В  ходе  выполнения этого задания был использован:
1) Яндекс Облако

2) Terraform со следующими файлами конфигурации:
- [cloud-config-base.yml](Files/Terraform/cloud-config-base.yaml)
- [.gitignore](Files/Terraform/.gitignore)
- [main.tf](Files/Terraform/main.tf)
- [output.tf](Files/Terraform/output.tf)
- [terraform.tfvars](Files/Terraform/terraform.tfvars)

3) Ansible playbook для установки Nginx со следующими файлами конфигурации:
- [ansible.cfg](Files/Ansible/ansible.cfg)
- [hosts.ini](Files/Ansible/hosts1.ini) и [nginx-playbook1.yml](Files/Ansible/nginx-playbook1.yml) - первый вариант плейбука
- [hosts.ini](Files/Ansible/hosts2.ini) и [nginx-playbook2.yml](Files/Ansible/nginx-playbook2.yml) - второй вариант плейбука

![alt text](<Screenshots/Задание 1-1.png>)

![alt text](<Screenshots/Задание 1-2.png>)

![alt text](<Screenshots/Задание 1-3.png>)

![alt text](<Screenshots/Задание 1-4.png>)

![alt text](<Screenshots/Задание 1-5.png>)

![alt text](<Screenshots/Задание 1-6.png>)

![alt text](<Screenshots/Задание 1-7.png>)

![alt text](<Screenshots/Задание 1-8.png>)

![alt text](<Screenshots/Задание 1-9.png>)

![alt text](<Screenshots/Задание 1-10.png>)

![alt text](<Screenshots/Задание 1-11.png>)

![alt text](<Screenshots/Задание 1-12.png>)

![alt text](<Screenshots/Задание 1-13.png>)

![alt text](<Screenshots/Задание 1-14.png>)

![alt text](<Screenshots/Задание 1-15.png>)

![alt text](<Screenshots/Задание 1-16.png>)

![alt text](<Screenshots/Задание 1-17.png>)























----------------------------------------------------------------------------------------------------------------
