FROM python:3.11-alpine

LABEL description="Agent Dashboard Web Server" \
      maintainer="devops-agent-hub"

WORKDIR /app

# Copy server and static assets
COPY server.py dashboard.html analytics.html ./

# Create data directory for SQLite (writable by nobody)
RUN mkdir -p /app/data && chown nobody:nogroup /app/data

ENV DASHBOARD_PORT=8686

EXPOSE ${DASHBOARD_PORT}

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:${DASHBOARD_PORT}/api/health || exit 1

USER nobody

ENTRYPOINT ["python3", "server.py"]
CMD ["8686"]
