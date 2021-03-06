# Домашнее задание к занятию "12.4 Развертывание кластера на собственных серверах, лекция 2"

## Модуль 12. Администрирование кластера Kubernetes

### Студент: Иван Жиляев

>Новые проекты пошли стабильным потоком. Каждый проект требует себе несколько кластеров: под тесты и продуктив. Делать все руками — не вариант, поэтому стоит автоматизировать подготовку новых кластеров.

## Задание 1: Подготовить инвентарь kubespray
>Новые тестовые кластеры требуют типичных простых настроек. Нужно подготовить инвентарь и проверить его работу. Требования к инвентарю:
>* подготовка работы кластера из 5 нод: 1 мастер и 4 рабочие ноды;
>* в качестве CRI — containerd;
>* запуск etcd производить на мастере.

За основу своего инвентаря я взял [пример inventory.ini](https://github.com/kubernetes-sigs/kubespray/blob/master/inventory/sample/inventory.ini) из github-репозитория kubespray. Для использования CRI containerd я добавил переменную `container_manager=containerd` всем хостам в инвентаре.  
В итоге, убрав лишнее и добавив нужное получился такой инвентарь: [inventory.ini](./inventory.ini).

## Задание 2 (*): подготовить и проверить инвентарь для кластера в AWS
>Часть новых проектов хотят запускать на мощностях AWS. Требования похожи:
>* разворачивать 5 нод: 1 мастер и 4 рабочие ноды;
>* работать должны на минимально допустимых EC2 — t3.small.
