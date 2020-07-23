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
  title='CPU usage: ' + nodeName,
  datasource='$datasource',
  format='percent',
).addTarget(
  prometheus.target(
    'sum by (mode)(rate(node_cpu_seconds_total{instance=~"' + nodeName + '"}[2m])) * 100',
    legendFormat='{{ mode }}',
  )
);


local diskThroughput(nodeName) =
  grafana.graphPanel.new(
    title='Disk throughput: ' + nodeName,
    datasource='$datasource',
    format='Bps',
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

local networkThroughput(nodeName) =
  grafana.graphPanel.new(
    title='Network throughput: ' + nodeName,
    datasource='$datasource',
    format='bps',
  ).addTarget(
    prometheus.target(
      'rate(node_network_receive_bytes_total{instance=~"' + nodeName + '",device=~"$net_device"}[2m])',
      legendFormat='rx-{{ device }}',
    )
  ).addTarget(
    prometheus.target(
      'rate(node_network_transmit_bytes_total{instance=~"' + nodeName + '",device=~"$net_device"}[2m])',
      legendFormat='tx-{{ device }}',
    )
  );

local networkPackets(nodeName) =
  grafana.graphPanel.new(
    title='Network packets: ' + nodeName,
    datasource='$datasource',
    format='pps',
  ).addTarget(
    prometheus.target(
      'rate(node_network_receive_packets_total{instance=~"' + nodeName + '",device=~"$net_device"}[2m])',
      legendFormat='rx-{{ device }}',
    )
  ).addTarget(
    prometheus.target(
      'rate(node_network_transmit_packets_total{instance=~"' + nodeName + '",device=~"$net_device"}[2m])',
      legendFormat='tx-{{ device }}',
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


local containerCPU(nodeName) = grafana.graphPanel.new(
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

local containerMemory(nodeName) = grafana.graphPanel.new(
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

local nodeCount = grafana.graphPanel.new(
  title='Number of nodes',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'sum(kube_node_info{})',
    legendFormat='Number of nodes',
  )
);

local nsCount = grafana.graphPanel.new(
  datasource='$datasource',
  title='Namespace count'
).addTarget(
  prometheus.target(
    'count(kube_namespace_created{})',
    legendFormat='Namespace count',
  )
);

local podCount = grafana.graphPanel.new(
  datasource='$datasource',
  title='Pod count',
).addTarget(
  prometheus.target(
    'sum(kube_pod_status_phase{}) by (phase)',
    legendFormat='{{phase}} pods',
  )
);

local secretCount = grafana.graphPanel.new(
  title='Secret count',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'count(kube_secret_info{})',
    legendFormat='secrets',
  )
);

local deployCount = grafana.graphPanel.new(
  title='Deployment count',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'count(kube_deployment_labels{})',
    legendFormat='Deployments',
  )
);

local cmCount = grafana.graphPanel.new(
  title='Configmap count',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'count(kube_configmap_info{})',
    legendFormat='Configmaps',
  )
);

local svcCount = grafana.graphPanel.new(
  title='Service count',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'sum(kube_service_spec_type) by (type)',
    legendFormat='{{type}}',
  )
);


local reqCount = grafana.graphPanel.new(
  title='400/500 requests',
  datasource='$datasource',
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

local apiReqCount = grafana.graphPanel.new(
  title='API Request Count',
  datasource='$datasource',
).addTarget(
  prometheus.target(
    'sum by (instance,service) (rate(apiserver_request_count{}[2m]))',
    legendFormat='{{service}} - {{instance}}',
  )
);

local top10ContMem = grafana.graphPanel.new(
  title='Top 10 container memory',
  datasource='$datasource',
  format='bytes'
).addTarget(
  prometheus.target(
    'topk(10, container_memory_rss{namespace!="",name!=""})',
    legendFormat='{{ namespace }} - {{ name }}',
  )
);

local top10ContCPU = grafana.graphPanel.new(
  title='Top 10 container CPU',
  datasource='$datasource',
  format='percent'
).addTarget(
  prometheus.target(
    'topk(10,rate(container_cpu_usage_seconds_total{namespace!="",name!=""}[2m]))*100',
    legendFormat='{{ namespace }} - {{ name }}',
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
    label: 'NIC',
    type: 'query',
    multi: true,
    includeAll: true,
  },
)

// Dashboard definition

.addPanel(
  grafana.row.new(title='Monitoring stack', collapse=true)
  .addPanel(promReplMemUsage, gridPos={ x: 0, y: 1, w: 24, h: 12 })
  , { gridPos: { x: 0, y: 0, w: 24, h: 1 } }
)

.addPanel(
  grafana.row.new(title='Kubelet', collapse=true).addPanels(
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
    nodeCount { gridPos: { x: 0, y: 0, w: 8, h: 8 } },
    nsCount { gridPos: { x: 8, y: 0, w: 8, h: 8 } },
    podCount { gridPos: { x: 16, y: 0, w: 8, h: 8 } },
    secretCount { gridPos: { x: 0, y: 8, w: 8, h: 8 } },
    deployCount { gridPos: { x: 8, y: 8, w: 8, h: 8 } },
    cmCount { gridPos: { x: 16, y: 8, w: 8, h: 8 } },
    svcCount { gridPos: { x: 0, y: 16, w: 8, h: 8 } },
    reqCount { gridPos: { x: 8, y: 16, w: 8, h: 8 } },
    apiReqCount { gridPos: { x: 16, y: 16, w: 8, h: 8 } },
    top10ContMem { gridPos: { x: 0, y: 24, w: 12, h: 8 } },
    top10ContCPU { gridPos: { x: 12, y: 24, w: 12, h: 8 } },
  ]
), { gridPos: { x: 0, y: 1, w: 0, h: 8 } })


.addPanel(grafana.row.new(title='Master: $_master_node', collapse=true, repeat='_master_node').addPanels(
  [
    nodeCPU('$_master_node') { gridPos: { x: 0, y: 0, w: 12, h: 8 } },
    nodeMemory('$_master_node') { gridPos: { x: 12, y: 0, w: 12, h: 8 } },
    diskThroughput('$_master_node') { gridPos: { x: 0, y: 8, w: 12, h: 8 } },
    diskIOPS('$_master_node') { gridPos: { x: 12, y: 8, w: 12, h: 8 } },
    networkThroughput('$_master_node') { gridPos: { x: 0, y: 16, w: 8, h: 8 } },
    networkPackets('$_master_node') { gridPos: { x: 8, y: 16, w: 8, h: 8 } },
    networkDrop('$_master_node') { gridPos: { x: 16, y: 16, w: 8, h: 8 } },
    containerMemory('$_master_node') { gridPos: { x: 0, y: 24, w: 12, h: 8 } },
    containerCPU('$_master_node') { gridPos: { x: 12, y: 24, w: 12, h: 8 } },
  ],
), { gridPos: { x: 0, y: 1, w: 0, h: 8 } })

.addPanel(grafana.row.new(title='Worker: $_worker_node', collapse=true, repeat='_worker_node').addPanels(
  [
    nodeCPU('$_worker_node') { gridPos: { x: 0, y: 0, w: 12, h: 8 } },
    nodeMemory('$_worker_node') { gridPos: { x: 12, y: 0, w: 12, h: 8 } },
    diskThroughput('$_worker_node') { gridPos: { x: 0, y: 8, w: 12, h: 8 } },
    diskIOPS('$_worker_node') { gridPos: { x: 12, y: 8, w: 12, h: 8 } },
    networkThroughput('$_worker_node') { gridPos: { x: 0, y: 16, w: 8, h: 8 } },
    networkPackets('$_worker_node') { gridPos: { x: 8, y: 16, w: 8, h: 8 } },
    networkDrop('$_worker_node') { gridPos: { x: 16, y: 16, w: 8, h: 8 } },
    containerMemory('$_worker_node') { gridPos: { x: 0, y: 24, w: 12, h: 8 } },
    containerCPU('$_worker_node') { gridPos: { x: 12, y: 24, w: 12, h: 8 } },
    networkConnections('$_worker_node') { gridPos: { x: 0, y: 32, w: 12, h: 8 } },
  ],
), { gridPos: { x: 0, y: 1, w: 0, h: 8 } })

.addPanel(grafana.row.new(title='Infra: $_infra_node', collapse=true, repeat='_infra_node').addPanels(
  [
    nodeCPU('$_infra_node') { gridPos: { x: 0, y: 0, w: 12, h: 8 } },
    nodeMemory('$_infra_node') { gridPos: { x: 12, y: 0, w: 12, h: 8 } },
    diskThroughput('$_infra_node') { gridPos: { x: 0, y: 8, w: 12, h: 8 } },
    diskIOPS('$_infra_node') { gridPos: { x: 12, y: 8, w: 12, h: 8 } },
    networkThroughput('$_infra_node') { gridPos: { x: 0, y: 16, w: 8, h: 8 } },
    networkPackets('$_infra_node') { gridPos: { x: 8, y: 16, w: 8, h: 8 } },
    networkDrop('$_infra_node') { gridPos: { x: 16, y: 16, w: 8, h: 8 } },
    containerMemory('$_infra_node') { gridPos: { x: 0, y: 24, w: 12, h: 8 } },
    containerCPU('$_infra_node') { gridPos: { x: 12, y: 24, w: 12, h: 8 } },
  ],
), { gridPos: { x: 0, y: 1, w: 0, h: 8 } })
