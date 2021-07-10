# Домашнее задание к занятию "12.5 Сетевые решения CNI"

## Модуль 12. Администрирование кластера Kubernetes

### Студент: Иван Жиляев

>После работы с Flannel появилась необходимость обеспечить безопасность для приложения. Для этого лучше всего подойдет Calico.

## Задание 1: установить в кластер CNI плагин Calico
>Для проверки других сетевых решений стоит поставить отличный от Flannel плагин — например, Calico. Требования: 
>* установка производится через ansible/kubespray;
>* после применения следует настроить политику доступа к hello world извне.

Для того, чтобы поставить плагин нужен поднятый кластер. Подготовим три ВМ на хосте с Hyper-V с помощью [Vagrantfile](Vagrantfile) и заполним инвентарь kubespray для дальнейшей установки кластера в конфигурации "1 мастер и 2 воркера".

Для обеспечения связи с нодами поссредством Ansible сделаем следующее:
- возьмём подготовленный для kubespray [inventory-файл](inventory.ini), где укажем ip-адреса ВМ и добавим переменную `ansible_user=vagrant`
- скопируем ключ ssh на управляемые хосты с помощью подготовленной таски [copy_ssh_id.yml](ansible/roles/init_role/tasks/copy_ssh_id.yml).

Первый пункт выполнен вручную, а второй - с помощью команды:

```
ansible-playbook -i inventory.ini -t init -k -c paramiko ansible/playbook.yml
```

Проверим что Ansible может управлять целевым хостом:

```
ansible-playbook -i inventory.ini -t check-connection ansible/playbook.yml
```

Теперь можно установить кластер через kubespray:

```
virtualenv venv
source venv/bin/activate
git clone https://github.com/kubernetes-incubator/kubespray
echo kubespray/ > .gitignore
cd kubespray
git checkout v2.16.0
pip install -r requirements.txt
ansible-playbook -i ../inventory.ini -e kube_network_plugin=calico -b cluster.yml
deactivate
```

Для упрощения задачи работать с кластером будем с мастер-ноды из окружения root-а, ведь kubespray создал в нём конфигурацию для подключения:

```
ssh vagrant@192.168.88.26
sudo -i
```

Для возможности доступа к сервисам "снаружи" кластера добавим балансировщик [MetalLB](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#a-pure-software-solution-metallb):

```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
```

Настроим MetalLB с помощью configmap-а, в котором укажем "внешние" адреса кластера - [metallb-cm.yaml](metallb-cm.yaml).

Так как нам понадобится проверять работу сети на сервисе `hello world`, то поднимем его:

```
kubectl create deployment hello-deployment --image=k8s.gcr.io/echoserver:1.4
```

Доступ к сервису `hello world` из внешних сетей будет обеспечен балансировщиком MetalLB автоматически при создании службы для сервиса с `spec.type=LoadBalancer` - [оф.документация](https://metallb.universe.tf/usage/). Создадим описание службы [service.yaml](service.yaml) и применим его в кластере:

```
kubectl apply -f service.yaml
```

Проверка показала, что сервис доступен при обращении на "внешний" адрес кластера. Так и должно быть, ведь мы пока не настраивали никаких ограничений.

Теперь, для выполнения условия задания, ограничим доступ к сервису через политики доступа. Откроем доступ трафику "извне" к сервису только с адреса `192.168.88.39`. Для этого создадим описание правила в файле [networkpolicy.yaml](networkpolicy.yaml) и применим его в кластере:

```
kubectl apply -f networkpolicy.yaml
```

Проверка показала успех: с системы с адресом `192.168.88.39` сервис отображается, а для системы с адресом `192.168.88.248` сервис недоступен.

## Задание 2: изучить, что запущено по умолчанию
>Самый простой способ — проверить командой calicoctl get <type>. Для проверки стоит получить список нод, ipPool и profile.
>Требования: 
>* установить утилиту calicoctl;
>* получить 3 вышеописанных типа в консоли.

Благодаря тому, что кластер был развёрнут с помощью kubespray, утилита calicoctl уже присутствовала на мастер-ноде. Осталось только запросить требуемые объекты:

```
root@master1:~# calicoctl get node 
NAME      
master1   
node1     
node2     

root@master1:~# calicoctl get ipPool
NAME           CIDR             SELECTOR   
default-pool   10.233.64.0/18   all()      

root@master1:~# calicoctl get profile
NAME                                                 
projectcalico-default-allow                          
kns.default                                          
kns.kube-node-lease                                  
kns.kube-public                                      
kns.kube-system                                      
kns.metallb-system                                   
ksa.default.default                                  
ksa.kube-node-lease.default                          
ksa.kube-public.default                              
ksa.kube-system.attachdetach-controller              
ksa.kube-system.bootstrap-signer                     
ksa.kube-system.calico-kube-controllers              
ksa.kube-system.calico-node                          
ksa.kube-system.certificate-controller               
ksa.kube-system.clusterrole-aggregation-controller   
ksa.kube-system.coredns                              
ksa.kube-system.cronjob-controller                   
ksa.kube-system.daemon-set-controller                
ksa.kube-system.default                              
ksa.kube-system.deployment-controller                
ksa.kube-system.disruption-controller                
ksa.kube-system.dns-autoscaler                       
ksa.kube-system.endpoint-controller                  
ksa.kube-system.endpointslice-controller             
ksa.kube-system.endpointslicemirroring-controller    
ksa.kube-system.expand-controller                    
ksa.kube-system.generic-garbage-collector            
ksa.kube-system.horizontal-pod-autoscaler            
ksa.kube-system.job-controller                       
ksa.kube-system.kube-proxy                           
ksa.kube-system.namespace-controller                 
ksa.kube-system.node-controller                      
ksa.kube-system.nodelocaldns                         
ksa.kube-system.persistent-volume-binder             
ksa.kube-system.pod-garbage-collector                
ksa.kube-system.pv-protection-controller             
ksa.kube-system.pvc-protection-controller            
ksa.kube-system.replicaset-controller                
ksa.kube-system.replication-controller               
ksa.kube-system.resourcequota-controller             
ksa.kube-system.root-ca-cert-publisher               
ksa.kube-system.service-account-controller           
ksa.kube-system.service-controller                   
ksa.kube-system.statefulset-controller               
ksa.kube-system.token-cleaner                        
ksa.kube-system.ttl-controller                       
ksa.metallb-system.controller                        
ksa.metallb-system.default                           
ksa.metallb-system.speaker 
```
