# Домашнее задание к занятию "12.2 Команды для работы с Kubernetes"

## Модуль 12. Администрирование кластера Kubernetes

### Студент: Иван Жиляев

>Кластер — это сложная система, с которой крайне редко работает один человек. Квалифицированный devops умеет наладить работу всей команды, занимающейся каким-либо сервисом.
>После знакомства с кластером вас попросили выдать доступ нескольким разработчикам. Помимо этого требуется служебный аккаунт для просмотра логов.

## Задание 1: Запуск пода из образа в деплойменте
>Для начала следует разобраться с прямым запуском приложений из консоли. Такой подход поможет быстро развернуть инструменты отладки в кластере. Требуется запустить деплоймент на основе образа из hello world уже через deployment. Сразу стоит запустить 2 копии приложения (replicas=2). 
>
>Требования:
> * пример из hello world запущен в качестве deployment
> * количество реплик в deployment установлено в 2
> * наличие deployment можно проверить командой kubectl get deployment
> * наличие подов можно проверить командой kubectl get pods

Для подготовки деплоймента воспользуемся туториалом с официального сайка кубернетиса - [https://kubernetes.io/docs/tutorials/kubernetes-basics/deploy-app/deploy-intro/](https://kubernetes.io/docs/tutorials/kubernetes-basics/deploy-app/deploy-intro/), а также справкой kubectl.

В результате цель достигнута:

```
ivan@kubang:~$ kubectl create deployment hello-deployment --image=k8s.gcr.io/echoserver:1.4 --replicas=2
deployment.apps/hello-deployment created
ivan@kubang:~$ kubectl get deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
hello-deployment   2/2     2            2           24s
ivan@kubang:~$ kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
hello-deployment-c8b94f448-dmt78   1/1     Running   0          31s
hello-deployment-c8b94f448-qnggb   1/1     Running   0          31s
```

## Задание 2: Просмотр логов для разработки
>Разработчикам крайне важно получать обратную связь от штатно работающего приложения и, еще важнее, об ошибках в его работе. 
>Требуется создать пользователя и выдать ему доступ на чтение конфигурации и логов подов в app-namespace.
>
>Требования: 
> * создан новый токен доступа для пользователя
> * пользователь прописан в локальный конфиг (~/.kube/config, блок users)
> * пользователь может просматривать логи подов и их конфигурацию (kubectl logs pod <pod_id>, kubectl describe pod <pod_id>)

Создание пользователя будет производиться с помощью [статьи на Хабре](https://habr.com/ru/company/flant/blog/470503/).

На мастер-ноде миникуба создадим пользователя, сгенерируем для него сертификат и подпишем его CA кубернетиса.

```
useradd developer && cd /home/developer
openssl genrsa -out developer.key 2048
openssl req -new -key developer.key -out developer.csr -subj "/CN=developer"
openssl x509 -req -in developer.csr -CA /home/vagrant/.minikube/ca.crt -CAkey /home/vagrant/.minikube/ca.key -CAcreateserial -out developer.crt -days 500
mkdir .certs && mv developer.crt developer.key .certs
```

Для упрощения проверки работы сертификатов сменим их вдалельца на vagrant:
```
sudo chown -R vagrant: /home/developer/.certs
```

Теперь можно добавить в конфиг kubectl пользователя _developer_ используя сертификат и ключ из папки _/home/developer/.certs_.

```
kubectl config set-credentials developer --client-certificate=/home/developer/.certs/developer.crt --client-key=/home/developer/.certs/developer.key
```

Проверим что запись о пользователе появилась в конфигурации kubectl:

```
vagrant@netology-minikube:/home/developer$ kubectl config view | grep -A8 "users:"
users:
- name: developer
  user:
    client-certificate: /home/developer/.certs/developer.crt
    client-key: /home/developer/.certs/developer.key
- name: minikube
  user:
    client-certificate: /home/vagrant/.minikube/profiles/minikube/client.crt
    client-key: /home/vagrant/.minikube/profiles/minikube/client.key
```

Добавим контекст для работы с кластером под новым пользователем, переключимся на него и проверим успешность операции командами:

```
kubectl config set-context developer --cluster=minikube --user=developer
kubectl config use-context developer
kubectl config get-contexts
```

Осталось выдать новому пользователю права на работу с объектами в кластере. Предположим, что новые права будут востребованы в различных будущих неймспейсах, поэтому воспользуемся объектом типа ClusterRole, а не Role ([отличия этих объектов тут](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)).  
По примеру из [оф.документации](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#referring-to-resources) создадим файл с описанием желаемых полномочий - [ClusterRole-pod-and-pod-logs-reader.yaml](./ClusterRole-pod-and-pod-logs-reader.yaml). Также создадим файл описания применения роли к пользователю - [RoleBinding-developer.yaml](./RoleBinding-developer.yaml).  
В другом терминале, под администратором кластера, добавим новую ClusterRole и RoleBinding:

```
kubectl create -f ClusterRole-pod-and-pod-logs-reader.yaml
kubectl apply -f RoleBinding-developer.yaml
```

Вернёмся в терминал с настроенным контекстом на нового пользователя и проверим успешность процедуры:

```
vagrant@netology-minikube:/home/developer$ kubectl config get-contexts
CURRENT   NAME        CLUSTER    AUTHINFO    NAMESPACE
*         developer   minikube   developer   
          minikube    minikube   minikube    default
vagrant@netology-minikube:/home/developer$ kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
hello-deployment-c8b94f448-dmt78   1/1     Running   0          12h
hello-deployment-c8b94f448-qnggb   1/1     Running   0          12h
```

## Задание 3: Изменение количества реплик 
>Поработав с приложением, вы получили запрос на увеличение количества реплик приложения для нагрузки. Необходимо изменить запущенный deployment, увеличив количество реплик до 5. Посмотрите статус запущенных подов после увеличения реплик. 
>
>Требования:
> * в deployment из задания 1 изменено количество реплик на 5
> * проверить что все поды перешли в статус running (kubectl get pods)

Для решения задачи нам надо изменить параметр созданного ранее deployment-а. Воспользуемся командой `scale`:

```
ivan@kubang:~$ kubectl scale --replicas=5 deployment hello-deployment 
deployment.apps/hello-deployment scaled
ivan@kubang:~$ kubectl get po
NAME                               READY   STATUS    RESTARTS   AGE
hello-deployment-c8b94f448-8ctx9   1/1     Running   0          3s
hello-deployment-c8b94f448-bxkqh   1/1     Running   0          3s
hello-deployment-c8b94f448-dmt78   1/1     Running   0          12h
hello-deployment-c8b94f448-qnggb   1/1     Running   0          12h
hello-deployment-c8b94f448-rk89z   1/1     Running   0          3s
```
