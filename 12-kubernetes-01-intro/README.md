# Домашнее задание к занятию "12.1 Компоненты Kubernetes"

## Модуль 12. Администрирование кластера Kubernetes

### Студент: Иван Жиляев

>Вы DevOps инженер в крупной компании с большим парком сервисов. Ваша задача — разворачивать эти продукты в корпоративном кластере. 

## Задача 1: Установить Minikube

>Для экспериментов и валидации ваших решений вам нужно подготовить тестовую среду для работы с Kubernetes. Оптимальное решение — развернуть на рабочей машине Minikube.
>
>### Как поставить на AWS:
>- создать EC2 виртуальную машину (Ubuntu Server 20.04 LTS (HVM), SSD Volume Type) с типом **t3.small**. Для работы потребуется настроить Security Group для доступа по ssh. Не забудьте указать keypair, он потребуется для подключения.
>- подключитесь к серверу по ssh (ssh ubuntu@<ipv4_public_ip> -i <keypair>.pem)
>- установите миникуб и докер следующими командами:
>  - curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
>  - chmod +x ./kubectl
>  - sudo mv ./kubectl /usr/local/bin/kubectl
>  - sudo apt-get update && sudo apt-get install docker.io conntrack -y
>  - curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
>- проверить версию можно командой minikube version
>- переключаемся на root и запускаем миникуб: minikube start --vm-driver=none
>- после запуска стоит проверить статус: minikube status
>- запущенные служебные компоненты можно увидеть командой: kubectl get pods --namespace=kube-system
>
>### Для сброса кластера стоит удалить кластер и создать заново:
>- minikube delete
>- minikube start --vm-driver=none
>
>Возможно, для повторного запуска потребуется выполнить команду: sudo sysctl fs.protected_regular=0
>
>Инструкция по установке Minikube - [ссылка](https://kubernetes.io/ru/docs/tasks/tools/install-minikube/)
>
>**Важно**: t3.small не входит во free tier, следите за бюджетом аккаунта и удаляйте виртуалку.

Для проведения экспериментов с Minikube в изолированной среде я использую возможности своей домашней инфраструктуры и создам отдельную ВМ на хосте Windows с Hyper-V. Подготовка ВМ будет выполняться с помощью запуска [Vagrantfile](Vagrantfile), а дальнейшее управление - с помощью Ansible.

После размещения Vagrantfile на гипервизоре установим ВМ командой:

```
vagrant up
```

Настройка Ansible на control-node будет заключаться в следующем:
- в inventory-файле укажем ip-адрес полученной ВМ и ansible_user=vagrant
- копирование ключа ssh на управляемый хост с помощью подготовленной таски [copy_ssh_id.yml](ansible/roles/init_role/tasks/copy_ssh_id.yml).

Первый пункт выполнен вручную, а второй - с помощью команды:

```
ansible-playbook -i ansible/inventory/hosts -t init -k -c paramiko ansible/playbook.yml
```

Проверим что Ansible может управлять целевым хостом:

```
ansible-playbook -i ansible/inventory/hosts -t check-connection ansible/playbook.yml
```

Теперь можно подключиться напрямую по ssh чтобы запустить и проверить кластер:

```
ssh vagrant@192.168.88.25
```
```
sudo apt install conntrack
minikube start --driver=none
minikube status
kubectl get pods --namespace=kube-system
```


## Задача 2: Запуск Hello World

>После установки Minikube требуется его проверить. Для этого подойдет стандартное приложение hello world. А для доступа к нему потребуется ingress.
>
>- развернуть через Minikube тестовое приложение по [туториалу](https://kubernetes.io/ru/docs/tutorials/hello-minikube/#%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5-%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D0%B0-minikube)
>- установить аддоны ingress и dashboard

Согласно туториалу последовательно выполним команды:

```
kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4
kubectl get deployments
kubectl get pods
kubectl get events
kubectl config view
kubectl expose deployment hello-node --type=LoadBalancer --port=8080
kubectl get services
minikube service hello-node
```

Проверить работу микросервиса можно командой:

```
curl -iv http://192.168.88.25:30482
```

Установим дополнения:

```
minikube addons list
minikube addons enable ingress
minikube addons enable dashboard
```

## Задача 3: Установить kubectl

>Подготовить рабочую машину для управления корпоративным кластером. Установить клиентское приложение kubectl.
>- подключиться к minikube 
>- проверить работу приложения из задания 2, запустив port-forward до кластера

Установка kubectl:

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

Настройка алиаса и автодополнения ввода:

```
sudo kubectl completion bash >/etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
```

После перезагрузки терминала можно сконфигурировать kubectl на рабочей станции для подключения к minikube. Для этого скопируем сертификаты пользователя и настроим kubectl:

```
mkdir -p netology-minikube/.minikube/profiles/minikube/
scp vagrant@192.168.88.25:~/.minikube/ca.crt netology-minikube/.minikube/ca.crt
scp vagrant@192.168.88.25:~/.minikube/profiles/minikube/client.* netology-minikube/.minikube/profiles/minikube/
kubectl config set-credentials minikube --client-certificate=netology-minikube/.minikube/profiles/minikube/client.crt --client-key=netology-minikube/.minikube/profiles/minikube/client.key
kubectl config set-context minikube --cluster=minikube --user=minikube
kubectl config set-cluster minikube --certificate-authority=netology-minikube/.minikube/ca.crt --server=https://192.168.88.25:8443
```

Сделаем проверку подключения к minikube:

```
ivan@kubang:~/study/netology-devkub/12-kubernetes-01-intro$ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
hello-node-7567d9fdc9-8cwzs   1/1     Running   0          50m
```

Теперь можно перепроверить работу приложения из задания 2 - зайти браузером на страницу микросервиса, либо проверить через curl:

```
curl -iv http://192.168.88.25:30482
```

## Задача 4 (*): собрать через ansible (необязательное)

>Профессионалы не делают одну и ту же задачу два раза. Давайте закрепим полученные навыки, автоматизировав выполнение заданий  ansible-скриптами. При выполнении задания обратите внимание на доступные модули для k8s под ansible.
> - собрать роль для установки minikube на aws сервисе (с установкой ingress)
> - собрать роль для запуска в кластере hello world

