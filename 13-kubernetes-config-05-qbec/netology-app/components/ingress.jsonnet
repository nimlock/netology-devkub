
local p = import '../params.libsonnet';
local params = p.components.ingress;
local front_params = p.components.front_svc_and_deploy;

{
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
        name: params.name
    },
    spec: {
        rules: [
            {
                host: params.host,
                http: {
                    paths: [
                        {
                            backend: {
                                service: {
                                    name: front_params.name,
                                    port: {
                                        number: front_params.port
                                    }
                                }
                            },
                            pathType: 'ImplementationSpecific'
                        }
                    ]
                }
            }
        ]
    }
}
