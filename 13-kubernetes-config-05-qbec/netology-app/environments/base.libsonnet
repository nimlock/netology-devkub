
// this file has the baseline default parameters
{
  components: {
    back_svc_and_deploy: {
      name: 'app-back',
      labels: {
        app: 'netology',
        type: 'back'
      },
      replicas: 1,
      port: 9000,
      endpoint: 9000,
      env: [
        {
          name: 'DATABASE_URL',
          value: 'postgres://postgres:postgres@app-db:5432/news'
        }
      ],
      image: 'nimlock/netology-homework-13.xx-backend:production'
    },
    front_svc_and_deploy: {
      name: 'app-front',
      labels: {
        app: 'netology',
        type: 'front'
      },
      replicas: 1,
      port: 80,
      endpoint: 80,
      env: [
        {
          name: 'BASE_URL',
          value: 'http://task2.13-1.netology'
        }
      ],
      image: 'nimlock/netology-homework-13.xx-frontend:production'
    },
    db_svc_and_statefulset: {
      name: 'app-db',
      labels: {
        app: 'netology',
        type: 'db'
      },
      replicas: 1,
      port: 5432,
      env: [
        {
          name: 'POSTGRES_DB',
          value: 'news'
        },
        {
          name: 'POSTGRES_USER',
          value: 'postgres'
        },
        {
          name: 'POSTGRES_PASSWORD',
          value: 'postgres'
        }
      ],
      image: 'postgres:13-alpine'
    },
    ingress: {
      name: 'netology-ingress',
      host: 'task1.13-1.netology'
    }
  }
}
