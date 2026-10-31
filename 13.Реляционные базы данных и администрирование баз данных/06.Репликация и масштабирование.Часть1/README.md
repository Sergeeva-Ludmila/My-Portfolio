# 13.06 Репликация и масштабирование.Часть1

----------------------------------------------------------------------------------------------------------------

## Задание 1

На лекции рассматривались режимы репликации: master-slave,master-master,опишите их различия.

*Ответить в свободной форме.*

## Ответ:

**Master‑Slave (ведущий‑ведомый,т.е однонаправленная репликация) — классическая асимметричная схема:**
1. Один источник истины.
- Все изменения (INSERT/UPDATE/DELETE) идут только на Master. Slave только читает данные и реплицирует изменения с Master.
2. Нагрузка распределяется.
- Master держит запись, Slave берут на себя чтение (репортные запросы, аналитика, веб‑приложение в режиме read‑only).
3. Отказоустойчивость частичная.
- Если падает Master, система перестаёт принимать записи;
- при грамотной настройке можно вручную или автоматически перевести один из Slave в роль Master.
4. Задержка репликации (replication lag).
- Slave может отставать на секунды или минуты — данные на нём не всегда «свежие». Это нормально и учитывается в логике приложения (критичные операции — на Master, отчёты — на Slave).
5. Простота настройки и предсказуемость.
- Конфликтов почти нет, потому что пишет только один сервер.

**Master‑Master (двунаправленная репликация) — симметричная схема, где оба узла могут принимать запись:**

1.Оба сервера — источники истины.
- Изменения, сделанные на любом из них, реплицируются на другой.
2. Риск конфликтов.
- Если две сессии одновременно меняют одну и ту же строку на разных узлах, возникает конфликт, который нужно разрешать (автоматически или вручную). В MySQL это особенно актуально при использовании AUTO_INCREMENT без правильной настройки auto_increment_offset и auto_increment_increment.
3. Сложность эксплуатации.
- Нужно тщательно настраивать автоинкременты, следить за консистентностью, иметь план разрешения конфликтов и отката.
4. Не всегда даёт «настоящую» высокую доступность.
- Без внешнего арбитра (HAProxy, Keepalived, Pacemaker и т. п.) переключение при падении узла часто делается вручную.
5. Чаще используется как переходный вариант или для специфических задач.
- Например, для географически распределённых офисов с локальной записью, либо как подготовка к шардированию. В современных архитектурах чаще выбирают либо Master‑Slave + автоматический фейловер, либо полноценные HA‑кластеры (Group Replication, Galera, Patroni).

**Ключевое отличие:** в Master‑Slave запись централизована (меньше конфликтов, проще), в Master‑Master запись распределена (больше гибкости, но выше риск проблем с консистентностью).

----------------------------------------------------------------------------------------------------------------

## Задание 2

1. Выполните конфигурацию master-slave репликации, примером можно пользоваться из лекции.
2. Приложите скриншоты конфигурации, выполнения работы: состояния и режимы работы серверов.

## Ответ:

- docker-compose up -d
- docker ps
- docker exec -it mysql-master mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW VARIABLES LIKE 'server_id';"
- docker exec -it mysql-slave mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW VARIABLES LIKE 'server_id';"
-docker exec -it mysql-master mysql -u root -psecret06 -e "
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'replpass';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
"
- docker exec -it mysql-master mysql -u root -psecret06 -e "SHOW MASTER STATUS;"
- docker exec -i mysql-slave mysql -u root -psecret06 -e "CHANGE MASTER TO MASTER_HOST='mysql-mast
er', MASTER_PORT=3306, MASTER_USER='repl', MASTER_PASSWORD='replpass', MASTER_LOG_FILE='29643eebff2a-bin.000001', MASTER_LOG_POS=861;"
-

- docker exec -it mysql-master mysql -u root -p
- CREATE USER 'mila'@'%' IDENTIFIED WITH mysql_native_password BY 'SecretPassword21';
- GRANT REPLICATION SLAVE ON *.* TO 'mila'@'%';
- FLUSH PRIVILEGES;
- SELECT user, host, plugin FROM mysql.user WHERE user = 'mila';




docker exec -it mysql-slave mysql -u root -p

- CHANGE MASTER TO
  MASTER_HOST='mysql-master',
  MASTER_PORT=3306,
  MASTER_USER='mila',
  MASTER_PASSWORD='SecretPassword21',
  MASTER_AUTO_POSITION=1;

- START REPLICA;
- SHOW REPLICA STATUS\G
-


- GRANT REPLICATION SLAVE ON *.* TO 'mila'@'%';
- FLUSH PRIVILEGES;
- SELECT user, host, plugin FROM mysql.user WHERE user = 'mila';


STOP REPLICA;
RESET REPLICA;

CHANGE MASTER TO
  MASTER_HOST='mysql-slave',
  MASTER_PORT=3306,
  MASTER_USER='mila',
  MASTER_PASSWORD='SecretPassword21',
  MASTER_AUTO_POSITION=1;

START REPLICA;
SHOW REPLICA STATUS
docker exec -it mysql-master mysql -u root -p
USE repl_new;
CREATE TABLE IF NOT EXISTS mm_mytest (id INT AUTO_INCREMENT PRIMARY KEY, source VARCHAR(20));
exit

docker exec -it mysql-master mysql -u root -p
USE repl_new;
INSERT INTO mm_mytest (source) VALUES ('from-master');
SELECT * FROM mm_mytest;exit

exit

docker exec -it mysql-slave mysql -u root -p
USE repl_new;
SELECT * FROM mm_mytest;
exit


вариант 2

- docker exec -it mysql-master mysql -u root -p
- CREATE USER IF NOT EXISTS 'repluser'@'%' IDENTIFIED BY 'NewSecret';
- GRANT REPLICATION SLAVE ON *.* TO 'mila'@'%';
- FLUSH PRIVILEGES;
- SELECT user, host, plugin FROM mysql.user WHERE user = 'mila';
docker exec -i mysql-master mysql -u root -p${MYSQL_ROOT_PASSWORD} < master/master.sql

------------------------------------------------------------------------------------------------------

## адание 3*

1. Выполните конфигурацию master-master репликации. Произведите проверку.
2. Приложите скриншоты конфигурации, выполнения работы: состояния и режимы работы серверов.

## Ответ:

----------------------------------------------------------------------------------------------------------------