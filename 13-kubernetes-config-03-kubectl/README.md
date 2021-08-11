# Домашнее задание к занятию "13.3 работа с kubectl"

## Модуль 13. Конфигурация Kubernetes

### Студент: Иван Жиляев

## Задание 1: проверить работоспособность каждого компонента
>Для проверки работы можно использовать 2 способа: port-forward и exec. Используя оба способа, проверьте каждый компонент:
>* сделайте запросы к бекенду;
>* сделайте запросы к фронту;
>* подключитесь к базе данных.

Для проверки работоспособности сервисов через `port-forward` запустим "прокидывания" портов в фоне, чтобы затем проверить их обращаясь на адрес localhost и соответствующий порт:

```
root@master1:/home/vagrant/13.3# kubectl -n stage port-forward deployment/task1-deployment 9001:9000 &
[1] 527607
root@master1:/home/vagrant/13.3# Forwarding from 127.0.0.1:9001 -> 9000
Forwarding from [::1]:9001 -> 9000

root@master1:/home/vagrant/13.3# kubectl -n stage port-forward deployment/task1-deployment 81:80 &
[2] 527614
root@master1:/home/vagrant/13.3# Forwarding from 127.0.0.1:81 -> 80
Forwarding from [::1]:81 -> 80

root@master1:/home/vagrant/13.3# kubectl -n stage port-forward statefulset/task1-statefulset 5431:5432 &
[3] 583230
root@master1:/home/vagrant/13.3# Forwarding from 127.0.0.1:5431 -> 5432
Forwarding from [::1]:5431 -> 5432

root@master1:/home/vagrant/13.3# curl -X GET -I http://localhost:9001/api/news/
Handling connection for 9001
HTTP/1.1 200 OK
date: Wed, 11 Aug 2021 06:36:57 GMT
server: uvicorn
content-length: 5182
content-type: application/json

root@master1:/home/vagrant/13.3# curl -I http://localhost:81
Handling connection for 81
HTTP/1.1 200 OK
Server: nginx/1.19.5
Date: Wed, 11 Aug 2021 06:34:21 GMT
Content-Type: text/html
Content-Length: 448
Last-Modified: Sat, 10 Jul 2021 17:47:54 GMT
Connection: keep-alive
ETag: "60e9dd4a-1c0"
Accept-Ranges: bytes

root@master1:/home/vagrant/13.3# psql -h localhost -p 5431 -U postgres news -c "SELECT COUNT(*) FROM news;"
Handling connection for 5431
 count 
-------
    25
(1 row)
```

---

Проверка сервисов с помощью `exec` будет аналогична по форме запросов, за исключением того, что мы укажем оригинальные порты, т.к. запуск команд будет производится внутри самих подов, соответственно безо всякой трансляции портов:

```
root@master1:/home/vagrant/13.3# kubectl -n stage exec deployment/task1-deployment -c netology-backend -- curl -X GET -I http://localhost:9000/api/news/
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0  5182    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 OK
date: Wed, 11 Aug 2021 06:51:19 GMT
server: uvicorn
content-length: 5182
content-type: application/json

root@master1:/home/vagrant/13.3# kubectl -n stage exec deployment/task1-deployment -c netology-frontend -- curl -I http://localhost:80
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0HTTP/1.1 200 OK
Server: nginx/1.19.5
Date: Wed, 11 Aug 2021 06:51:48 GMT
Content-Type: text/html
Content-Length: 448
Last-Modified: Sat, 10 Jul 2021 17:47:54 GMT
Connection: keep-alive
ETag: "60e9dd4a-1c0"
Accept-Ranges: bytes

  0   448    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0

root@master1:/home/vagrant/13.3# kubectl -n stage exec statefulset/task1-statefulset -- psql -h localhost -p 5432 -U postgres news -c "SELECT COUNT(*) FROM news;"
 count 
-------
    25
(1 row)
```

## Задание 2: ручное масштабирование
>При работе с приложением иногда может потребоваться вручную добавить пару копий. Используя команду kubectl scale, попробуйте увеличить количество бекенда и фронта до 3. После уменьшите количество копий до 1. Проверьте, на каких нодах оказались копии после каждого действия (kubectl describe).

Для бОльшей наглядности проверку распределения подов по нодам будем выполнять командой `kubectl -n stage get pod --selector=app=task1-app -o wide`.  
Выполним заданную последовательность действий по масштабированию:

```
root@master1:/home/vagrant/13.3# kubectl -n stage get pod --selector=app=task1-app -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP             NODE    NOMINATED NODE   READINESS GATES
task1-deployment-67d596c49b-g495x   2/2     Running   0          2d    10.233.96.31   node2   <none>           <none>

root@master1:/home/vagrant/13.3# kubectl -n stage scale deployment task1-deployment --replicas=3
deployment.apps/task1-deployment scaled

root@master1:/home/vagrant/13.3# kubectl -n stage get pod --selector=app=task1-app -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP             NODE    NOMINATED NODE   READINESS GATES
task1-deployment-67d596c49b-g495x   2/2     Running   0          2d    10.233.96.31   node2   <none>           <none>
task1-deployment-67d596c49b-tn4qd   2/2     Running   0          24s   10.233.96.34   node2   <none>           <none>
task1-deployment-67d596c49b-z4kbz   2/2     Running   0          24s   10.233.90.28   node1   <none>           <none>

root@master1:/home/vagrant/13.3# kubectl -n stage scale deployment task1-deployment --replicas=1
deployment.apps/task1-deployment scaled

root@master1:/home/vagrant/13.3# kubectl -n stage get pod --selector=app=task1-app -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP             NODE    NOMINATED NODE   READINESS GATES
task1-deployment-67d596c49b-z4kbz   2/2     Running   0          79s   10.233.90.28   node1   <none>           <none>
```
