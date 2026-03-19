FROM grafana/grafana:latest

USER root

# Copy provisioning configuration into the image
# Datasources: Google Cloud Monitoring (uses ADC / Cloud Run service account)
# Dashboards: pre-built Cloud Run dashboard
COPY provisioning/ /etc/grafana/provisioning/

USER grafana

# Grafana defaults to port 3000; Cloud Run is configured to forward to this port
EXPOSE 3000

ENV GF_PATHS_PROVISIONING=/etc/grafana/provisioning
# Allow read-only anonymous access (viewers); login required for admin
ENV GF_AUTH_ANONYMOUS_ENABLED=true
ENV GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer
# Admin credentials are injected at deploy time via GF_SECURITY_ADMIN_PASSWORD
ENV GF_SECURITY_ADMIN_USER=admin
