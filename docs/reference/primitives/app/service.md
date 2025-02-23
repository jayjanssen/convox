# Service

A Service is a horizontally-scalable collection of durable [Processes](process.md).

[Processes](process.md) that belong to a Service are automatically restarted upon termination.

Services can be scaled to a static count or autoscaled in a range based on metrics.

## Definition

```
services:
  web:
    build: .
    health: /check
    port: 5000
    scale: 3
```

```
services:
  web:
    agent: false
    annotations:
      - test.annotation.org/value=foobar
    build:
      manifest: Dockerfile
      path: .
    command: bin/web
    deployment:
      minimum: 25
      maximum: 100
    domain: ${WEB_HOST}
    drain: 10
    environment:
      - FOO
      - BAR=qux
    health:
      grace: 10
      interval: 5
      path: /check
      timeout: 3
    internal: false
    port: 5000
    ports:
      - 5001
      - 5002
    privileged: false
    scale:
      cooldown:
        down: 180
        up: 30
      count: 1-3
      cpu: 128
      memory: 512
      targets:
        cpu: 50
        memory: 80
    singleton: false
    sticky: true
    termination:
      grace: 45
    test: make test
    timeout: 180
    tls:
      redirect: true
```

| Attribute     | Type       | Default             | Description                                                                                                                                |
| ------------- | ---------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `agent`       | boolean    | false               | Set to `true` to declare this Service as an [Agent](../../../configuration/agents.md)                                                      |
| `annotations` | list       |                     | A list of annotation keys and values to populate the metadata for the deployed pods and their serviceaccounts                              |
| `build`       | string/map | .                   | Build definition (see below)                                                                                                               |
| `command`     | string     | `CMD` of Dockerfile | The command to run to start a [Process](process.md) for this Service                                                                       |
| `deployment`  | map        |                     | Manual control over deployment parameters                                                                                                  |
| `domain`      | string     |                     | A custom domain(s) (comma separated) to route to this Service                                                                              |
| `drain`       | number     |                     | The number of seconds to wait for connections to drain when terminating a [Process](process.md) of this Service                            |
| `environment` | list       |                     | A list of environment variables (with optional defaults) to populate from the [Release](release.md) environment                            |
| `health`      | string/map | /                   | Health check definition (see below)                                                                                                        |
| `image`       | string     |                     | An external Docker image to use for this Service (supercedes `build`)                                                                      |
| `internal`    | boolean    | false               | Set to `true` to make this Service only accessible inside the Rack                                                                         |
| `port`        | string     |                     | The port that the default Rack balancer will use to [route incoming traffic](../../../configuration/load-balancers.md)                     |
| `ports`       | list       |                     | A list of ports available for internal [service discovery](../../../configuration/service-discovery.md) or custom [Balancers](balancer.md) |
| `privileged`  | boolean    | true                | Set to `false` to prevent [Processes](process.md) of this Service from running as root inside their container                              |
| `scale`       | map        | 1                   | Define scaling parameters (see below)                                                                                                      |
| `singleton`   | boolean    | false               | Set to `true` to prevent extra [Processes](process.md) of this Service from being started during deployments                               |
| `sticky`      | boolean    | false               | Set to `true` to enable sticky sessions                                                                                                    |
| `termination` | map        |                     | Termination related configuration                                                                                                          |
| `test`        | string     |                     | A command to run to test this Service when running `convox test`                                                                           |
| `timeout`     | number     | 60                  | Timeout period (in seconds) for reading/writing requests to/from your service                                                              |
| `tls`         | map        |                     | TLS-related configuration                                                                                                                  |

> Environment variables **must** be declared to be populated for a Service.

### build

| Attribute  | Type   | Default    | Description                                                   |
| ---------- | ------ | ---------- | ------------------------------------------------------------- |
| `manifest` | string | Dockerfile | The filename of the Dockerfile                                |
| `path`     | string | .          | The path (relative to `convox.yml`) to build for this Service |

> Specifying `build` as a string will set the `path` and leave the other values as defaults.

### deployment

| Attribute | Type   | Default | Description                                                                      |
| --------- | ------ | ------- | -------------------------------------------------------------------------------- |
| `maximum` | number | 200     | The maximum percentage of Processes to allow during rolling deploys              |
| `minimum` | number | 50      | The minimum percentage of healthy Processes to keep alive during rolling deploys |

### health

| Attribute  | Type   | Default | Description                                                                                      |
| ---------- | ------ | ------- | ------------------------------------------------------------------------------------------------ |
| `grace`    | number | 5       | The number of seconds to wait for a [Process](process.md) to start before starting health checks |
| `interval` | number | 5       | The number of seconds between health checks                                                      |
| `path`     | string | /       | The path to request for health checks                                                            |
| `timeout`  | number | 4       | The number of seconds to wait for a successful response                                          |

> Specifying `health` as a string will set the `path` and leave the other values as defaults.

### scale

| Attribute  | Type       | Default | Description                                                                                                   |
| ---------- | ---------- | ------- | ------------------------------------------------------------------------------------------------------------- |
| `cooldown` | number/map | 60      | The cooldown period between scaling events to control how aggressive your service scales down/up              |
| `count`    | number     | 1       | The number of [Processes](process.md) to run for this Service. For autoscaling use a range, e.g. `1-5`        |
| `cpu`      | number     | 128     | The number of CPU units to reserve for [Processes](process.md) of this Service where 1024 units is a full CPU |
| `memory`   | number     | 256     | The number of MB of RAM to reserve for [Processes](process.md) of this Service                                |
| `targets`  | map        |         | Target metrics to trigger autoscaling                                                                         |

> Specifying `scale` as a number will set the `count` and leave the other values as defaults.

### scale.cooldown

| Attribute | Type   | Default | Description                                                                                |
| --------- | ------ | ------- | ------------------------------------------------------------------------------------------ |
| `down`    | number | 60      | Sets the cooldown period between scaling events after a scale down event has occurred      |
| `up`      | number | 60      | Sets the cooldown period between scaling events after a scale up event has occurred        |

> Specifying `cooldown` as a number will set the cooldown period for both scaling directions at the same time.

### scale.targets

| Attribute | Type   | Default | Description                                                                                |
| --------- | ------ | ------- | ------------------------------------------------------------------------------------------ |
| `cpu`     | number |         | The percentage of CPU utilization to target for [Processes](process.md) of this Service    |
| `memory`  | number |         | The percentage of memory utilization to target for [Processes](process.md) of this Service |

### termination

| Attribute  | Type    | Default | Description                                                                                      |
| ---------- | ------- | ------- | ------------------------------------------------------------------------------------------------ |
| `grace`    | number  | 30      | The number of seconds to wait for [Processes](process.md) to gracefully exit before killing them |

### tls

| Attribute  | Type    | Default | Description                                                                          |
| ---------- | ------- | ------- | ------------------------------------------------------------------------------------ |
| `redirect` | boolean | true    | Whether or not HTTP requests should be redirected to HTTPS using a 308 response code |

## Command Line Interface

### Listing Services

    $ convox services -a myapp
    SERVICE  DOMAIN                                PORTS
    web      web.convox.0a1b2c3d4e5f.convox.cloud  443:5000

### Scaling a Service

    $ convox scale web --count 3 --cpu 256 --memory 1024 -a myapp`1
    Scaling web... OK

### Restarting a Service

    $ convox services restart web -a myapp
    Restarting web... OK

> Restarting a Service will begin a rolling restart with graceful termination of each [Process](process.md) of the Service.