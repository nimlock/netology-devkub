
// this file has the param overrides for the stage environment
local base = import './base.libsonnet';

base {
  components +: {
    back_svc_and_deploy +: {
      replicas: 3,
      env: [
        {
          name: 'DATABASE_URL',
          value: 'postgres://postgres:postgres@app-db:5432/news'
        }
      ],
      image: 'nimlock/netology-homework-13.5-backend:production'
    },
    front_svc_and_deploy +: {
      replicas: 3,
      env: [
        {
          name: 'BASE_URL',
          value: 'http://production.13-5.netology'
        }
      ],
      image: 'nimlock/netology-homework-13.5-frontend:production'
    },
    db_svc_and_statefulset +: {
      replicas: 1,
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
    ingress +: {
      host: 'production.13-5.netology'
    },
    out_svc_and_endpoint: {
      name: 'some-out-service',
      port: 80
    }
  }
}
