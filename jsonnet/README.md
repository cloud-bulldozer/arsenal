# Jsonnet grafana dashboards

Managing grafana dashboards in a CVS is not an easy task, since the exported dashboards by Grafana do not have always the same json layout due to the nature of the own json format. 
When exporting a Grafana dashboard json keys may be exported in different order. In addition, dealing with such complex json files is not an easy task since it's usually required import & export the full dashboard to perform a minimal modification or update.

Jsonnet based dashboards is an effort to improve the manageability of grafana json dashboards by leveraging the libraries included at the project [grafonnet-lib](https://github.com/grafana/grafonnet-lib). Using this mechanism of dashboards as code will improve versioning and make simplify collaboration.

## How to

To make a change, simply update the desired .jsonnet dashboard file and push your changes. The project is configured to automatically render updated .jsonnet files into .json format, and push these updated dashboards to Marquez.

Alternatively, you can render the jsonnet files manually by doing the following: 

Render a jsonnet file is as simple as executing `jsonnet <jsonnet_template>`. The jsonnet binary is not included in this repo, though binary builds can be found in its official [repository](https://github.com/google/jsonnet/releases).
A makefile has been included to automate jsonnet formatting and rendering tasks. Executing `make` downloads the jsonnet binary and renders the templates at the *rendered* directory.

i.e.

```shell
$ make
mkdir -p bin rendered tmp
git clone --depth 1 https://github.com/grafana/grafonnet-lib.git templates/grafonnet-lib
Cloning into 'templates/grafonnet-lib'...
Downloading jsonnet binary
curl -s -L https://github.com/google/jsonnet/releases/download/v0.15.0/jsonnet-bin-v0.15.0-linux.tar.gz | tar xzf - -C bin
Formating template templates/ocp-performance.jsonnet
bin/jsonnetfmt templates/ocp-performance.jsonnet > tmp/ocp-performance.jsonnet
mv tmp/ocp-performance.jsonnet templates/ocp-performance.jsonnet
Building template templates/ocp-performance.jsonnet
bin/jsonnet templates/ocp-performance.jsonnet > rendered/ocp-performance.json
$ ls rendered
ocp-ingress-controller.json ocp-performance.json
```

In order to clean up the environment execute `make clean`.

In order to lint the templates using `jsonnetfmt`execute `make format`

```shell
$ make clean
Cleaning up
rm -rf bin rendered tmp templates/grafonnet-lib
```

## Templates available

The following templates are available:
- OpenShift Performance Dashboard
- API Performance Dashboard
- Etcd Dashboard
- UPerf Results Dashboard
- Pgbench Dashboard
- YCSB Dashboard
- Vegeta Dashboard
