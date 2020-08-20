local grafana = import 'grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;

// Helper functions

local nodeMemory(nodeName) =
  grafana.graphPanel.new(
    title='System Memory: ' + nodeName,
    datasource='$datasource',
    format='bytes'
  )
  .addTarget(
    prometheus.target(
      'node_memory_Active_bytes{instance=~"' + nodeName + '"}',
      legendFormat='Active',
    )
  )
  .addTarget(
    prometheus.target(
      'node_memory_MemTotal_bytes{instance=~"' + nodeName + '"}',
      legendFormat='Total',
    )
  )
  .addTarget(
    prometheus.target(
      'node_memory_Cached_bytes{instance=~"' + nodeName + '"} + node_memory_Buffers_bytes{instance=~"' + nodeName + '"}',
      legendFormat='Cached + Buffers',
    )
  )
  .addTarget(
    prometheus.target(
      'node_memory_MemAvailable_bytes{instance=~"' + nodeName + '"} - (node_memory_Cached_bytes{instance=~"' + nodeName + '"} + node_memory_Buffers_bytes{instance=~"' + nodeName + '"})',
      legendFormat='Available',
    )
  );


local nodeCPU(nodeName) = grafana.graphPanel.new(
  title='CPU Basic: ' + nodeName,
  datasource='$datasource',
  format='percent',
).addTarget(
  prometheus.target(
    'sum by (instance)(rate(node_cpu_seconds_total{mode="system",instance=~"' + nodeName + '",job=~".*",clustername=~"$clustername"}[5m])) * 100',
    legendFormat='Busy system',
  )
).addTarget(
  prometheus.target(
    'sum by (instance)(rate(node_cpu_seconds_total{mode="user",instance=~"' + nodeName + '",job=~".*",clustername=~"$clustername"}[5m])) * 100',
    legendFormat='Busy user',
  )
).addTarget(
  prometheus.target(
    'sum by (instance)(rate(node_cpu_seconds_total{mode="iowait",instance=~"' + nodeName + '",job=~".*",clustername=~"$clustername"}[5m])) * 100',
    legendFormat='Busy iowait',
  )
).addTarget(
  prometheus.target(
    'sum by (instance)(rate(node_cpu_seconds_total{mode=~".*irq",instance=~"' + nodeName + '",job=~".*",clustername=~"$clustername"}[5m])) * 100',
    legendFormat='Busy IRQs',
  )
).addTarget(
  prometheus.target(
    'sum (rate(node_cpu_seconds_total{mode!="idle",mode!="user",mode!="system",mode!="iowait",mode!="irq",mode!="softirq",instance=~"' + nodeName + '",job=~".*",clustername=~"$clustername"}[5m])) * 100',
    legendFormat='Busy Other',
  )
).addTarget(
  prometheus.target(
    'sum by (mode)(rate(node_cpu_seconds_total{mode="idle",instance=~"' + nodeName + '",job=~".*",clustername=~"$clustername"}[5m])) * 100',
    legendFormat='Idle',
  )
);


local diskThroughput(nodeName) =
  grafana.graphPanel.new(
    title='Disk throughput: ' + nodeName,
    datasource='$datasource',
    format='Bps',
    legend_values=true,
    legend_alignAsTable=true,
    legend_current=true,
    legend_max=true,
    legend_min=true,
    legend_avg=true,
    legend_hideEmpty=true,
    legend_hideZero=true,
  ).addTarget(
    prometheus.target(
      'rate(node_disk_read_bytes_total{device=~"$block_device",instance=~"' + nodeName + '"}[2m])',
      legendFormat='{{ device }} - read',
    )
  ).addTarget(
    prometheus.target(
      'rate(node_disk_written_bytes_total{device=~"$block_device",instance=~"' + nodeName + '"}[2m])',
      legendFormat='{{ device }} - write',
    )
  );

local diskIOPS(nodeName) =
  grafana.graphPanel.new(
    title='Disk IOPS: ' + nodeName,
    datasource='$datasource',
    format='iops',
    legend_values=true,
    legend_alignAsTable=true,
    legend_current=true,
    legend_max=true,
    legend_min=true,
    legend_avg=true,
    legend_hideEmpty=true,
    legend_hideZero=true,
  ).addTarget(
    prometheus.target(
      'rate(node_disk_reads_completed_total{device=~"$block_device",instance=~"' + nodeName + '"}[2m])',
      legendFormat='{{ device }} - read',
    )
  ).addTarget(
    prometheus.target(
      'rate(node_disk_writes_completed_total{device=~"$block_device",instance=~"' + nodeName + '"}[2m])',
      legendFormat='{{ device }} - write',
    )
  );

local networkUtilization(nodeName) =
  grafana.graphPanel.new(
    title='Network Utilization: ' + nodeName,
    datasource='$datasource',
    format='bps',
    legend_values=true,
    legend_alignAsTable=true,
    legend_current=true,
    legend_max=true,
    legend_min=true,
    legend_avg=true,
    legend_hideEmpty=true,
    legend_hideZero=true,
  ).addTarget(
    prometheus.target(
      'rate(node_network_receive_bytes_total{instance=~"' + nodeName + '",device=~"$net_device",clustername=~"$clustername"}[5m]) * 8',
      legendFormat='{{instance}} - {{device}} - RX',
    )
  ).addTarget(
    prometheus.target(
      'rate(node_network_transmit_bytes_total{instance=~"' + nodeName + '",device=~"$net_device",clustername=~"$clustername"}[5m]) * 8',
      legendFormat='{{instance}} - {{device}} - TX',
    )
  );

local networkPackets(nodeName) =
  grafana.graphPanel.new(
    title='Network Packets: ' + nodeName,
    datasource='$datasource',
    format='pps',
    legend_values=true,
    legend_alignAsTable=true,
    legend_current=true,
    legend_max=true,
    legend_min=true,
    legend_avg=true,
    legend_hideEmpty=true,
    legend_hideZero=true,
  ).addTarget(
    prometheus.target(
      'rate(node_network_receive_packets_total{instance=~"' + nodeName + '",device=~"$net_device",clustername=~"$clustername"}[5m]) * 8',
      legendFormat='{{instance}} - {{device}} - RX',
    )
  ).addTarget(
    prometheus.target(
      'rate(node_network_transmit_packets_total{instance=~"' + nodeName + '",device=~"$net_device",clustername=~"$clustername"}[5m]) * 8',
      legendFormat='{{instance}} - {{device}} - TX',
    )
  );

local networkDrop(nodeName) =
  grafana.graphPanel.new(
    title='Network packets drop: ' + nodeName,
    datasource='$datasource',
    format='pps',
  ).addTarget(
    prometheus.target(
      'rate(node_network_receive_drop_total{instance=~"' + nodeName + '"}[2m])',
      legendFormat='rx-drop-{{ device }}',
    )
  ).addTarget(
    prometheus.target(
      'rate(node_network_transmit_drop_total{instance=~"' + nodeName + '"}[2m])',
      legendFormat='tx-drop-{{ device }}',
    )
  );

local networkConnections(nodeName) =
  grafana.graphPanel.new(
    title='Network Connections: ' + nodeName,
    datasource='$datasource',
    legend_min=true,
    legend_max=true,
    legend_avg=true,
    legend_current=true,
    legend_alignAsTable=true,
    legend_values=true,
    legend_hideEmpty=true,
    legend_hideZero=true,
    transparent=true,
  )
  {
    fill: 0,
    seriesOverrides: [{
      alias: 'conntrack_entries',
    }],
    yaxes: [{ show: true }, { show: false }],
  }
  .addTarget(
    prometheus.target(
      'node_nf_conntrack_entries{instance="' + nodeName + '"}',
      legendFormat='conntrack_entries',
    )
  ).addTarget(
    prometheus.target(
      'node_nf_conntrack_entries_limit{instance="' + nodeName + '"}',
      legendFormat='conntrack_limit',
    )
  );


local top10containerCPU(nodeName) = grafana.graphPanel.new(
  title='Top 10 Container CPU usage: ' + nodeName,
  datasource='$datasource',
  format='percent',
  nullPointMode='null as zero',
).addTarget(
  prometheus.target(
    'topk(10, sum(rate(container_cpu_usage_seconds_total{name!="",node=~"' + nodeName + '",namespace!="",namespace=~"$namespace"}[2m])) by (namespace, pod, container)) * 100',
    legendFormat='{{ namespace }}: {{ pod }}-{{ container }}',
  )
);

local top10containerMemory(nodeName) = grafana.graphPanel.new(
  title='Top 10 Container Memory usage: ' + nodeName,
  datasource='$datasource',
  format='bytes',
  nullPointMode='null as zero',
).addTarget(
  prometheus.target(
    'topk(10, sum(rate(container_memory_rss{name!="",node=~"' + nodeName + '",namespace!="",namespace=~"$namespace"}[2m])) by (namespace, pod, container))',
    legendFormat='{{ namespace }}: {{ pod }}-{{ container }}',
  )
);

local containerCPUUsage(nodeName) = grafana.graphPanel.new(
  title='Container CPU usage: ' + nodeName,
  datasource='$datasource',
  format='percent',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_min=true,
  legend_avg=true,
  legend_hideEmpty=true,
  legend_hideZero=true,
).addTarget(
  prometheus.target(
    'sum(rate(container_cpu_usage_seconds_total{name!="",node=~"' + nodeName + '",clustername=~"$clustername",namespace!="",namespace=~"$namespace"}[5m])) by (namespace,name,service) * 100',
    legendFormat='{{ namespace }} - {{name}} - {{ service }}',
  )
);

local processRSS(nodeName) = grafana.graphPanel.new(
  title='Process RSS: ' + nodeName,
  datasource='$datasource',
  format='percent',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_min=true,
  legend_avg=true,
  legend_hideEmpty=true,
  legend_hideZero=true,
) {
  yaxes: [
    {
      format: 'bytes',
      show: 'true',
    },
    {
      format: 'short',
      show: 'false',
    },
  ],
}.addTarget(
  prometheus.target(
    'container_memory_rss{name!="",node=~"' + nodeName + '",clustername=~"$clustername",namespace!="",namespace=~"$namespace"}',
    legendFormat='{{ namespace }} - {{name}}',
  )
);

// Individual panel definitions

// Monitoring Stack

local promReplMemUsage = grafana.graphPanel.new(
  title='Prometheus Replica Memory usage',
  datasource='$datasource',
  format='bytes'
).addTarget(
  prometheus.target(
    'sum(container_memory_rss{pod="prometheus-k8s-1",namespace!="",name!="",container="prometheus"}) by (pod)',
    legendFormat='{{pod}}',
  )
).addTarget(
  prometheus.target(
    'sum(container_memory_rss{pod="prometheus-k8s-0",namespace!="",name!="",container="prometheus"}) by (pod)',
    legendFormat='{{pod}}',
  )
);

// Kubelet

local kubeletCPU = grafana.graphPanel.new(
  title='Top 10 Kubelet CPU usage',
  datasource='$datasource',
  format='percent',
  legend_values=true,
  legend_alignAsTable=true,
  legend_max=true,
  legend_rightSide=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'topk(10,rate(process_cpu_seconds_total{service="kubelet",job="kubelet"}[2m]))*100',
    legendFormat='kubelet - {{node}}',
  )
);

local crioCPU = grafana.graphPanel.new(
  title='Top 10 crio CPU usage',
  datasource='$datasource',
  format='percent',
  legend_values=true,
  legend_alignAsTable=true,
  legend_max=true,
  legend_rightSide=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'topk(10,rate(process_cpu_seconds_total{service="kubelet",job="crio"}[2m]))*100',
    legendFormat='crio - {{node}}',
  )
);

local kubeletMemory = grafana.graphPanel.new(
  datasource='$datasource',
  title='Top 10 Kubelet memory usage',
  format='bytes',
  legend_values=true,
  legend_alignAsTable=true,
  legend_max=true,
  legend_rightSide=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'topk(10,process_resident_memory_bytes{service="kubelet",job="kubelet"})',
    legendFormat='kubelet - {{node}}',
  )
);

local crioMemory = grafana.graphPanel.new(
  datasource='$datasource',
  title='Top 10 crio memory usage',
  format='bytes',
  legend_values=true,
  legend_alignAsTable=true,
  legend_max=true,
  legend_rightSide=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'topk(10,process_resident_memory_bytes{service="kubelet",job="crio"})',
    legendFormat='crio - {{node}}',
  )
);

// Cluster details

local current_node_count = grafana.statPanel.new(
  title='Current Node Count',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'sum(kube_node_info{clustername=~"$clustername"})',
    legendFormat='Number of nodes',
  )
).addTarget(
  prometheus.target(
    'sum(kube_node_status_condition{status="true"}) by (condition)',
    legendFormat='Node: {{ condition }}',
  )
);

local current_namespace_count = grafana.statPanel.new(
  title='Current Namespace Count',
  datasource='$datasource',
  graphMode='none',
).addTarget(
  prometheus.target(
    'count(kube_namespace_created{clustername=~"$clustername"})',
    legendFormat='Namespace Count',
  )
);

local current_pod_count = grafana.statPanel.new(
  title='Current Pod Count',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'sum(kube_pod_status_phase{phase="Running",namespace=~"$namespace",clustername=~"$clustername"})',
    legendFormat='Running Pods',
  )
).addTarget(
  prometheus.target(
    'sum(kube_pod_status_phase{phase="Succeeded",namespace=~"$namespace",clustername=~"$clustername"})',
    legendFormat='Succeeded Pods',
  )
).addTarget(
  prometheus.target(
    'sum(kube_pod_status_phase{phase="Failed",namespace=~"$namespace",clustername=~"$clustername"})',
    legendFormat='Failed Pods',
  )
).addTarget(
  prometheus.target(
    'sum(kube_pod_status_phase{phase="Failed",namespace=~"$namespace",clustername=~"$clustername"})',
    legendFormat='Failed Pods',
  )
);

local nodeCount = grafana.graphPanel.new(
  title='Number of nodes',
  datasource='$datasource',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'sum(kube_node_info{})',
    legendFormat='Number of nodes',
  )
);

local nsCount = grafana.graphPanel.new(
  datasource='$datasource',
  title='Namespace count',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'count(kube_namespace_created{})',
    legendFormat='Namespace count',
  )
);

local podCount = grafana.graphPanel.new(
  datasource='$datasource',
  title='Pod count',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'sum(kube_pod_status_phase{}) by (phase)',
    legendFormat='{{phase}} pods',
  )
);

local secretCount = grafana.graphPanel.new(
  title='Secret count',
  datasource='$datasource',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'count(kube_secret_info{})',
    legendFormat='secrets',
  )
);

local deployCount = grafana.graphPanel.new(
  title='Deployment count',
  datasource='$datasource',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'count(kube_deployment_labels{})',
    legendFormat='Deployments',
  )
);

local cmCount = grafana.graphPanel.new(
  title='Configmap count',
  datasource='$datasource',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'count(kube_configmap_info{})',
    legendFormat='Configmaps',
  )
);

local alerts = grafana.graphPanel.new(
  title='Alerts',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'topk(10,sum(ALERTS{severity!="none"}) by (alertname, severity))',
  )
);

local top10ContMem = grafana.graphPanel.new(
  title='Top 10 container memory',
  datasource='$datasource',
  format='bytes',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_rightSide=true,
  legend_sideWidth=250,
).addTarget(
  prometheus.target(
    'topk(10, container_memory_rss{namespace!="",name!=""})',
    legendFormat='{{ namespace }} - {{ name }}',
  )
);

local top10ContCPU = grafana.graphPanel.new(
  title='Top 10 container CPU',
  datasource='$datasource',
  format='percent',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_rightSide=true,
  legend_sideWidth=250,
).addTarget(
  prometheus.target(
    'topk(10,rate(container_cpu_usage_seconds_total{namespace!="",name!=""}[2m]))*100',
    legendFormat='{{ namespace }} - {{ name }}',
  )
);

local apiReqCount = grafana.graphPanel.new(
  title='API Request Count',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'sum by (instance,service) (rate(apiserver_request_count{}[2m]))',
    legendFormat='{{service}} - {{instance}}',
  )
);

local inflight_api_requests = grafana.graphPanel.new(
  title='Inflight API Requests',
  datasource='$datasource',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_sort='max',
  legend_sortDesc=true,
).addTarget(
  prometheus.target(
    'sum(apiserver_current_inflight_requests) by (requestKind)',
    legendFormat='{{ requestKind }}',
  )
);

local reqCount = grafana.graphPanel.new(
  title='400/500 requests',
  datasource='$datasource',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_rightSide=true,
  legend_sideWidth=150,
).addTarget(
  prometheus.target(
    '100 * sum by(service,job) (rate(rest_client_requests_total{code=~"4.."}[2m])) / sum by(service,job) (rate(rest_client_requests_total{}[2m]))',
    legendFormat='400s : {{service}} - {{job}}',
  )
).addTarget(
  prometheus.target(
    '100 * sum by(service,job) (rate(rest_client_requests_total{code=~"5.."}[2m])) / sum by(service,job) (rate(rest_client_requests_total{}[2m]))',
    legendFormat='500s : {{service}} - {{job}}',
  )
);

local api_requests_per_client = grafana.graphPanel.new(
  title='API Requests per client',
  datasource='$datasource',
  legend_values=true,
  legend_alignAsTable=true,
  legend_current=true,
  legend_max=true,
  legend_sort='max',
  legend_sortDesc=true,
  legend_rightSide=true,
).addTarget(
  prometheus.target(
    'sum(rate(apiserver_request_count{}[5m])) by (client,verb)',
    legendFormat='{{client}} - {{verb}}',
  )
);

local goroutines_count = grafana.graphPanel.new(
  title='Goroutines count',
  datasource='$datasource',
  legend_values=true,
  legend_alignAsTable=true,
  legend_rightSide=true,
).addTarget(
  prometheus.target(
    'topk(10, sum(go_goroutines{clustername=~"$clustername"}) by (job,instance))',
    legendFormat='{{job}} - {{instance}}',
  )
);

// Dashboard

grafana.dashboard.new(
  'OpenShift Performance',
  description='Performance dashboard for Red Hat OpenShift',
  time_from='now-1h',
  timezone='utc',
  refresh='30s',
  editable='true',
)


// Templates

.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    '',
  )
)

.addTemplate(
  grafana.template.new(
    '_master_node',
    '$datasource',
    'label_values(kube_node_role{role="master"}, node)',
    '',
    refresh=2,
  ) {
    label: 'Master',
    type: 'query',
    multi: true,
    includeAll: true,
  }
)

.addTemplate(
  grafana.template.new(
    '_worker_node',
    '$datasource',
    'label_values(kube_node_role{role="worker"}, node)',
    '',
    refresh=2,
  ) {
    label: 'Worker',
    type: 'query',
    multi: true,
    includeAll: true,
  },
)

.addTemplate(
  grafana.template.new(
    '_infra_node',
    '$datasource',
    'label_values(kube_node_role{role="infra"}, node)',
    '',
    refresh=2,
  ) {
    label: 'Infra',
    type: 'query',
    multi: true,
    includeAll: true,
  },
)


.addTemplate(
  grafana.template.new(
    'namespace',
    '$datasource',
    'label_values(kube_pod_info, namespace)',
    '',
    regex='/(openshift-.*|.*ripsaw.*|builder-.*|.*kube.*)/',
    refresh=2,
  ) {
    label: 'Namespace',
    type: 'query',
    multi: true,
    includeAll: true,
  },
)


.addTemplate(
  grafana.template.new(
    'block_device',
    '$datasource',
    'label_values(node_disk_written_bytes_total,device)',
    '',
    regex='/^(?:(?!dm|rb).)*$/',
    refresh=2,
  ) {
    label: 'Block device',
    type: 'query',
    multi: true,
    includeAll: true,
  },
)


.addTemplate(
  grafana.template.new(
    'net_device',
    '$datasource',
    'label_values(node_network_receive_bytes_total,device)',
    '',
    regex='/^((br|en|et).*)$/',
    refresh=2,
  ) {
    label: 'Network device',
    type: 'query',
    multi: true,
    includeAll: true,
  },
)

.addTemplate(
  grafana.template.new(
    'clustername',
    '$datasource',
    'label_values(process_cpu_seconds_total,clustername)',
    '',
    refresh=2,
  ) {
    type: 'query',
    multi: false,
    includeAll: false,
  },
)

// Dashboard definition

.addPanel(
  grafana.row.new(title='Monitoring stack', collapse=true)
  .addPanel(promReplMemUsage, gridPos={ x: 0, y: 1, w: 24, h: 12 })
  , { gridPos: { x: 0, y: 0, w: 24, h: 1 } }
)

.addPanel(
  grafana.row.new(title='Cluster Kubelet', collapse=true).addPanels(
    [
      kubeletCPU { gridPos: { x: 0, y: 2, w: 12, h: 8 } },
      crioCPU { gridPos: { x: 12, y: 2, w: 12, h: 8 } },
      kubeletMemory { gridPos: { x: 0, y: 2, w: 12, h: 8 } },
      crioMemory { gridPos: { x: 12, y: 2, w: 12, h: 8 } },
    ]
  ), { gridPos: { x: 0, y: 1, w: 24, h: 1 } }
)


.addPanel(grafana.row.new(title='Cluster Details', collapse=true).addPanels(
  [
    current_node_count { gridPos: { x: 0, y: 3, w: 8, h: 3 } },
    current_namespace_count { gridPos: { x: 8, y: 3, w: 8, h: 3 } },
    current_pod_count { gridPos: { x: 16, y: 3, w: 8, h: 3 } },
    nodeCount { gridPos: { x: 0, y: 11, w: 8, h: 8 } },
    nsCount { gridPos: { x: 8, y: 11, w: 8, h: 8 } },
    podCount { gridPos: { x: 16, y: 11, w: 8, h: 8 } },
    secretCount { gridPos: { x: 0, y: 19, w: 8, h: 8 } },
    deployCount { gridPos: { x: 8, y: 19, w: 8, h: 8 } },
    cmCount { gridPos: { x: 16, y: 19, w: 8, h: 8 } },
    alerts { gridPos: { x: 0, y: 27, w: 24, h: 8 } },
    top10ContMem { gridPos: { x: 0, y: 35, w: 12, h: 8 } },
    top10ContCPU { gridPos: { x: 12, y: 35, w: 12, h: 8 } },
    apiReqCount { gridPos: { x: 0, y: 43, w: 8, h: 8 } },
    inflight_api_requests { gridPos: { x: 8, y: 43, w: 8, h: 8 } },
    reqCount { gridPos: { x: 16, y: 43, w: 8, h: 8 } },
    api_requests_per_client { gridPos: { x: 0, y: 51, w: 12, h: 8 } },
    goroutines_count { gridPos: { x: 12, y: 51, w: 12, h: 8 } },
  ]
), { gridPos: { x: 0, y: 2, w: 24, h: 1 } })


.addPanel(grafana.row.new(title='Master: $_master_node', collapse=true, repeat='_master_node').addPanels(
  [
    nodeCPU('$_master_node') { gridPos: { x: 0, y: 0, w: 12, h: 8 } },
    nodeMemory('$_master_node') { gridPos: { x: 12, y: 0, w: 12, h: 8 } },
    diskThroughput('$_master_node') { gridPos: { x: 0, y: 8, w: 12, h: 8 } },
    diskIOPS('$_master_node') { gridPos: { x: 12, y: 8, w: 12, h: 8 } },
    networkUtilization('$_master_node') { gridPos: { x: 0, y: 16, w: 12, h: 8 } },
    networkPackets('$_master_node') { gridPos: { x: 12, y: 16, w: 12, h: 8 } },
    containerCPUUsage('$_master_node') { gridPos: { x: 0, y: 24, w: 12, h: 8 } },
    processRSS('$_master_node') { gridPos: { x: 12, y: 24, w: 12, h: 8 } },
  ],
), { gridPos: { x: 0, y: 1, w: 0, h: 8 } })

.addPanel(grafana.row.new(title='Worker: $_worker_node', collapse=true, repeat='_worker_node').addPanels(
  [
    nodeCPU('$_worker_node') { gridPos: { x: 0, y: 0, w: 12, h: 8 } },
    nodeMemory('$_worker_node') { gridPos: { x: 12, y: 0, w: 12, h: 8 } },
    diskThroughput('$_worker_node') { gridPos: { x: 0, y: 8, w: 12, h: 8 } },
    diskIOPS('$_worker_node') { gridPos: { x: 12, y: 8, w: 12, h: 8 } },
    networkUtilization('$_worker_node') { gridPos: { x: 0, y: 16, w: 12, h: 8 } },
    networkPackets('$_worker_node') { gridPos: { x: 12, y: 16, w: 12, h: 8 } },
    containerCPUUsage('$_worker_node') { gridPos: { x: 0, y: 24, w: 12, h: 8 } },
    processRSS('$_worker_node') { gridPos: { x: 12, y: 24, w: 12, h: 8 } },
  ],
), { gridPos: { x: 0, y: 1, w: 0, h: 8 } })

.addPanel(grafana.row.new(title='Infra: $_infra_node', collapse=true, repeat='_infra_node').addPanels(
  [
    nodeCPU('$_infra_node') { gridPos: { x: 0, y: 0, w: 12, h: 8 } },
    nodeMemory('$_infra_node') { gridPos: { x: 12, y: 0, w: 12, h: 8 } },
    diskThroughput('$_infra_node') { gridPos: { x: 0, y: 8, w: 12, h: 8 } },
    diskIOPS('$_infra_node') { gridPos: { x: 12, y: 8, w: 12, h: 8 } },
    networkUtilization('$_infra_node') { gridPos: { x: 0, y: 16, w: 12, h: 8 } },
    networkPackets('$_infra_node') { gridPos: { x: 12, y: 16, w: 12, h: 8 } },
    containerCPUUsage('$_infra_node') { gridPos: { x: 0, y: 24, w: 12, h: 8 } },
    processRSS('$_infra_node') { gridPos: { x: 12, y: 24, w: 12, h: 8 } },
  ],
), { gridPos: { x: 0, y: 1, w: 0, h: 8 } })
