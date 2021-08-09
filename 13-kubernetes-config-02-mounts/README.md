# Домашнее задание к занятию "13.2 разделы и монтирование"

## Модуль 13. Конфигурация Kubernetes

### Студент: Иван Жиляев

>Приложение запущено и работает, но время от времени появляется необходимость передавать между бекендами данные. А сам бекенд генерирует статику для фронта. Нужно оптимизировать это.
>Для настройки NFS сервера можно воспользоваться следующей инструкцией (производить под пользователем на сервере, у которого есть доступ до kubectl):
>* установить helm: curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
>* добавить репозиторий чартов: helm repo add stable https://charts.helm.sh/stable && helm repo update
>* установить nfs-server через helm: helm install nfs-server stable/nfs-server-provisioner
>
>В конце установки будет выдан пример создания PVC для этого сервера.

Helm уже был установлен через kubespray, остальные шаги вопросов не вызвали.

## Задание 1: подключить для тестового конфига общую папку
>В stage окружении часто возникает необходимость отдавать статику бекенда сразу фронтом. Проще всего сделать это через общую папку. Требования:
>* в поде подключена общая папка между контейнерами (например, /static);
>* после записи чего-либо в контейнере с беком файлы можно получить из контейнера с фронтом.

Для решения задачи будем использовать тип тома [emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir). Настройку будем производить на основе манифеста деплоймента, подготовленного в задании 13.1 - файл [task1-deployment.yaml](task1-deployment.yaml).

В манифесте достаточно добавить описание тома с типом `emptyDir` и использовать его в контейнерах. Для бОльшей наглядности том монтируется в контейнеры фронта и бэка в разные расположения: `/static-in-back/` и `/static-in-front/` соответственно.

Проверка показала, что данные записанные в `netology-backend` доступны в `netology-frontend`.

```
root@master1:/home/vagrant/13.2# k -n stage exec -it task1-deployment-67d596c49b-g495x -c netology-backend -- bash
root@task1-deployment-67d596c49b-g495x:/app# cd /static-in-back/
root@task1-deployment-67d596c49b-g495x:/static-in-back# echo "Some static info" > data.info
root@task1-deployment-67d596c49b-g495x:/static-in-back# exit
root@master1:/home/vagrant/13.2# k -n stage exec -it task1-deployment-67d596c49b-g495x -c netology-frontend -- bash
root@task1-deployment-67d596c49b-g495x:/app# cat /static-in-front/data.info 
Some static info
```

## Задание 2: подключить общую папку для прода
>Поработав на stage, доработки нужно отправить на прод. В продуктиве у нас контейнеры крутятся в разных подах, поэтому потребуется PV и связь через PVC. Сам PV должен быть связан с NFS сервером. Требования:
>* все бекенды подключаются к одному PV в режиме ReadWriteMany;
>* фронтенды тоже подключаются к этому же PV с таким же режимом;
>* файлы, созданные бекендом, должны быть доступны фронту.

Настройку будем производить также над готовым манифестом из прошлого задания в файле [task2-deployment.yaml](task2-deployment.yaml).

Для усложнения разместим бэк- и фронт-поды на разных нодах добавив параметр `nodeName:`. Также пусть и фронт и бэк имеют по две реплики - данные должны быть доступны во всех четырёх объектах.

Для возможности подключения NFS-томов установим на воркер-ноды NFS-клиент:

```
apt-get update && apt-get install -y nfs-common
```

Обновим прод-окружение из нового манифеста. Теперь можно убедиться, что даже при работе с разными подами на разных нодах данные в общем томе доступны для записи всем.

```
root@master1:/home/vagrant/13.2# k -n production get po -o wide
NAME                                      READY   STATUS    RESTARTS   AGE     IP             NODE    NOMINATED NODE   READINESS GATES
task2-deployment-back-7cf8bbd998-hnw5q    1/1     Running   0          25m     10.233.90.27   node1   <none>           <none>
task2-deployment-back-7cf8bbd998-ppsdt    1/1     Running   0          25m     10.233.90.26   node1   <none>           <none>
task2-deployment-front-6df7459cc4-j4fk5   1/1     Running   0          25m     10.233.96.33   node2   <none>           <none>
task2-deployment-front-6df7459cc4-lkzq7   1/1     Running   0          25m     10.233.96.32   node2   <none>           <none>
task2-statefulset-0                       1/1     Running   1          3d23h   10.233.96.28   node2   <none>           <none>
root@master1:/home/vagrant/13.2# k -n production exec task2-deployment-back-7cf8bbd998-hnw5q -- sh -c 'echo "back1 output" > /nfs-in-back/common.file'
root@master1:/home/vagrant/13.2# k -n production exec task2-deployment-back-7cf8bbd998-ppsdt -- sh -c 'echo "back2 output" >> /nfs-in-back/common.file'
root@master1:/home/vagrant/13.2# k -n production exec task2-deployment-front-6df7459cc4-j4fk5 -- sh -c 'echo "front1 output" >> /nfs-in-front/common.file'
root@master1:/home/vagrant/13.2# k -n production exec task2-deployment-front-6df7459cc4-lkzq7 -- sh -c 'echo "front2 output" >> /nfs-in-front/common.file'
root@master1:/home/vagrant/13.2# k -n production exec task2-deployment-front-6df7459cc4-lkzq7 -- cat /nfs-in-front/common.file
back1 output
back2 output
front1 output
front2 output
```
