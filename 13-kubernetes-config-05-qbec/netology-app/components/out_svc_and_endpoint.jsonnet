local env = std.extVar('qbec.io/env');

local callFunc = function () (
    local p = import '../params.libsonnet';
    local params = p.components.out_svc_and_endpoint;

    [
        {
            apiVersion: 'v1',
            kind: 'Service',
            metadata: {
                name: params.name
            },
            spec: {
                ports: [
                    {
                        port: params.port,
                        protocol: 'TCP',
                        targetPort: params.port
                    }
                ],
            }
        },
        {
            apiVersion: 'v1',
            kind: 'Endpoints',
            metadata: {    
                name: params.name
            },
            subsets: [
                {
                    addresses: [
                        {
                            ip: '139.59.205.180'
                        }
                    ],
                    ports: [
                        {
                            port: params.port
                        }
                    ]
                }
            ]
        }
    ]
);

if env == 'production' then callFunc