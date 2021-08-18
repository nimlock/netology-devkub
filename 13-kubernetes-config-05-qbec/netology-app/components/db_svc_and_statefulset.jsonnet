
local p = import '../params.libsonnet';
local params = p.components.db_svc_and_statefulset;

[
    {
        apiVersion: 'v1',
        kind: 'Service',
        metadata: {
            labels: params.labels,
            name: params.name
        },
        spec: {
            ports: [
                {
                    port: params.port,
                    protocol: 'TCP'
                }
            ],
            selector: params.labels,
            clusterIP: 'None'
        }
    },
    {
        apiVersion: 'apps/v1',
        kind: 'StatefulSet',
        metadata: {
            labels: params.labels,
            name: params.name
        },
        spec: {
            replicas: params.replicas,
            selector: {
                matchLabels: params.labels
            },
            serviceName: params.name,
            template: {
                metadata: {
                    labels: params.labels
                },
                spec: {
                    containers: [
                        {
                            name: params.name,
                            env: params.env,
                            image: params.image,
                            imagePullPolicy: 'Always'
                        }
                    ],
                    dnsPolicy: 'ClusterFirst',
                    restartPolicy: 'Always',
                    schedulerName: 'default-scheduler',
                    securityContext: {},
                    terminationGracePeriodSeconds: 30
                }
            }
        }
    }
]

