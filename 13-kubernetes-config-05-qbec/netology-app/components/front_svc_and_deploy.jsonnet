
local p = import '../params.libsonnet';
local params = p.components.front_svc_and_deploy;

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
                    protocol: 'TCP',
                    targetPort: params.endpoint
                }
            ],
            selector: params.labels,
            type: 'ClusterIP'
        }
    },
    {
        apiVersion: 'apps/v1',
        kind: 'Deployment',
        metadata: {
            labels: params.labels,
            name: params.name
        },
        spec: {
            replicas: params.replicas,
            selector: {
                matchLabels: params.labels
            },
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
