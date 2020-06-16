local grafana = import 'grafonnet-lib/grafonnet/grafana.libsonnet';
local es = grafana.elasticsearch;

// Panels
local rps = grafana.graphPanel.new(
  title='RPS (rate of sent requests per second)',
  datasource='$datasource',
  format='bps',
  legend_max=true,
  legend_avg=true,
  legend_alignAsTable=true,
  legend_values=true,
  transparent= true,
)
  {
    yaxes: [{
      format: 'bps',
      show: 'true'
    },
    {
      format: 'pps',
      show: 'false'
    }],
    fill: 2
  }
.addTarget(
  es.target(
    query='uuid: $uuid AND cluster_name: $cluster_name AND user: $user AND hostname: $hostname AND targets: $targets AND iteration: $iteration',
    timeField='timestamp',
    metrics=[{
      field: 'rps',
      id: '1',
      meta: {},
      settings: {},
      transparent: true,
      type: 'sum',
    }],
    bucketAggs=[{
      field: 'timestamp',
      id: '2',
      settings: {
        interval: 'auto',
        min_doc_count: 0,
        trimEdges: null,
      },
      type: 'date_histogram',
    }],
  )
);


local throughput = grafana.graphPanel.new(
  title='Throughput (rate of successful requests per second)',
  datasource='$datasource',
  format='bps',
  legend_max=true,
  legend_avg=true,
  legend_alignAsTable=true,
  legend_values=true,
  transparent= true,
)
  {
    yaxes: [{
      format: 'bps',
      show: 'true'
    },
    {
      format: 'pps',
      show: 'false'
    }],
    fill: 2
  }
.addTarget(
  es.target(
    query='uuid: $uuid AND cluster_name: $cluster_name AND user: $user AND hostname: $hostname AND targets: $targets AND iteration: $iteration',
    timeField='timestamp',
    metrics=[{
      field: 'throughput',
      id: '1',
      meta: {},
      settings: {},
      transparent: true,
      type: 'sum',
    }],
    bucketAggs=[{
      field: 'timestamp',
      id: '2',
      settings: {
        interval: 'auto',
        min_doc_count: 0,
        trimEdges: null,
      },
      type: 'date_histogram',
    }],
  )
);

local results = grafana.tablePanel.new(
  title='Vegeta Result Summary',
  datasource='$datasource',
  transparent= true,
  styles= [
    {
      decimals: '2',
      pattern: 'Average p99_latency',
      type: 'number',
      unit: 'µs'
    },
     {
      decimals: '2',
      pattern: 'Average req_latency',
      type: 'number',
      unit: 'µs'
    },
    {
      decimals: '2',
      pattern: 'Average bytes_in',
      type: 'number',
      unit: 'bps'
    },
    {
      decimals: '2',
      pattern: 'Average bytes_out',
      type: 'number',
      unit: 'bps'
    }
  ],
)
.addTarget(
  es.target(
    query='uuid: $uuid AND cluster_name: $cluster_name AND user: $user AND hostname: $hostname AND targets: $targets AND iteration: $iteration',
    timeField='timestamp',
    bucketAggs=[
            {
              field: 'user.keyword',
              id: '1',
              settings: {
                min_doc_count: 1,
                order: 'desc',
                orderBy: '_term',
                size: '10',
              },
              type: 'terms'
            },
            {
              field: 'workers',
              id: '2',
              settings: {
                min_doc_count: 1,
                order: 'desc',
                orderBy: '_term',
                size: '10',
              },
              type: 'terms'
            },
            {
              field: 'requests',
              id: '3',
              settings: {
                min_doc_count: 1,
                order: 'desc',
                orderBy: '_term',
                size: '10',
              },
              type: 'terms'
            },
            {
              field: 'status_codes.200',
              id: '4',
              settings: {
                min_doc_count: 1,
                order: 'desc',
                orderBy: '_term',
                size: '10',
              },
              type: 'terms'
            },
          ],
          metrics=[
            {
              field: 'p99_latency',
              id: '5',
              type: 'avg'
            },
            {
              field: 'req_latency',
              id: '6',
              type: 'avg'
            },
            {
              field: 'bytes_in',
              id: '7',
              type: 'avg'
            },
            {
              field: 'bytes_out',
              id: '8',
              type: 'avg'
            },
          ],
  )
);

grafana.dashboard.new(
  'Vegeta Results Dashboard',
  description='',
  time_from='now-24h',
  editable='true',
)

.addTemplate(
  grafana.template.datasource(
    'datasource',
    'elasticsearch',
    'ripsaw-vegeta-results',
    label='vegeta-results datasource'
  )
)

.addTemplate(
  grafana.template.new(
    'uuid',
    '$datasource',
    '{"find": "terms", "field": "uuid.keyword"}',
    refresh=2,
  ) {
    type: 'query',
    multi: false,
    includeAll: true,
  }
)

.addTemplate(
  grafana.template.new(
    'cluster_name',
    '$datasource',
    '{"find": "terms", "field": "cluster_name.keyword"}',
    refresh=2,
  ) {
    type: 'query',
    multi: false,
    includeAll: true,
  }
)

.addTemplate(
  grafana.template.new(
    'user',
    '$datasource',
    '{"find": "terms", "field": "user.keyword"}',
    refresh=2,
  ) {
    type: 'query',
    multi: false,
    includeAll: true,
  }
)

.addTemplate(
  grafana.template.new(
    'hostname',
    '$datasource',
    '{"find": "terms", "field": "hostname.keyword"}',
    refresh=2,
  ) {
    type: 'query',
    multi: false,
    includeAll: true,
  }
)

.addTemplate(
  grafana.template.new(
    'targets',
    '$datasource',
    '{"find": "terms", "field": "targets.keyword"}',
    refresh=2,
  ) {
    type: 'query',
    multi: false,
    includeAll: true,
  }
)

.addTemplate(
  grafana.template.new(
    'iteration',
    '$datasource',
    '{"find": "terms", "field": "iteration"}',
    refresh=2,
  ) {
    type: 'query',
    multi: false,
    includeAll: true,
  }
)

.addTemplate(
  grafana.template.new(
    'keepalive',
    '$datasource',
    '{"find": "terms", "field": "keepalive"}',
    refresh=2,
  ) {
    type: 'query',
    multi: false,
    includeAll: true,
  }
)

.addPanel(rps, gridPos={ x: 0, y: 0, w: 12, h: 9 })
.addPanel(throughput, gridPos={ x: 12, y: 0, w: 12, h: 9 })
.addPanel(results, gridPos={ x: 0, y: 12, w: 24, h: 9 })
