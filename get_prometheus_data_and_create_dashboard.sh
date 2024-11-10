#!/bin/bash

#vars for URLs and creds
PROMETHEUS_URL="http://localhost:9090"
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

#user time range input (or default: 5 min)
read -p "Enter the time period for the query in minutes (default 5 minutes): " TIME_PERIOD
TIME_PERIOD=${TIME_PERIOD:-5}

#convert time to secs for query
START_TIME=$(date -d "now - ${TIME_PERIOD} minutes" +%s)
END_TIME=$(date +%s)

#query prom for CPU
QUERY="node_cpu_seconds_total"
STEP="60s"

echo "Querying Prometheus for $QUERY from $START_TIME to $END_TIME with step $STEP..."
curl -g "$PROMETHEUS_URL/api/v1/query_range?query=$QUERY&start=$START_TIME&end=$END_TIME&step=$STEP" -o prometheus_response.json

#check if prom query successeed
if [ $? -eq 0 ]; then
    echo "Prometheus query successful. Response saved to prometheus_response.json"
else
    echo "Error querying Prometheus."
    exit 1
fi

#create grafana dashboard and panel with API

#create dashboard JSON for grafana
DASHBOARD_JSON=$(cat <<EOF
{
  "dashboard": {
    "id": null,
    "title": "Prometheus CPU Usage Dashboard",
    "panels": [
      {
        "datasource": null,
        "targets": [
          {
            "expr": "$QUERY",
            "interval": "$STEP"
          }
        ],
        "gridPos": {"h": 9, "w": 24, "x": 0, "y": 0},
        "id": 1,
        "title": "CPU Usage",
        "type": "graph"
      }
    ],
    "schemaVersion": 22,
    "timezone": "browser",
    "time": {
      "from": "$START_TIME",
      "to": "$END_TIME"
    }
  },
  "overwrite": true
}
EOF
)

#send dashboard creation request to grafana
echo "Creating a new Grafana dashboard..."
curl -u "$GRAFANA_USER:$GRAFANA_PASS" -X POST -H "Content-Type: application/json" -d "$DASHBOARD_JSON" "$GRAFANA_URL/api/dashboards/db" -o grafana_dashboard_response.json

#check if dashboard creation successeed
if [ $? -eq 0 ]; then
    echo "Grafana dashboard created successfully."
else
    echo "Error creating Grafana dashboard."
    exit 1
fi

#get dashboard URL from response (for image download)
DASHBOARD_URL=$(jq -r '.dashboard.url' grafana_dashboard_response.json)

#create image download URL for the graph
GRAPH_IMAGE_URL="$GRAFANA_URL/render/d-solo/$DASHBOARD_URL?panelId=1&from=$START_TIME&to=$END_TIME&width=1000&height=500"

#download the graph as an image
echo "Downloading Grafana graph image..."
curl -u "$GRAFANA_USER:$GRAFANA_PASS" -o grafana_graph.png "$GRAPH_IMAGE_URL"

#check if graph image was downloaded
if [ $? -eq 0 ]; then
    echo "Grafana graph image downloaded successfully as grafana_graph.png"
else
    echo "Error downloading Grafana graph image."
    exit 1
fi

echo "Script execution completed. Prometheus data saved as prometheus_response.json and Grafana graph saved as grafana_graph.png."

