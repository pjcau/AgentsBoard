FROM swift:5.10-noble AS builder

RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Package.swift Package.resolved* ./
COPY Sources/ Sources/
COPY Tests/ Tests/

# Build Core + Server targets only (no macOS UI)
RUN swift build --target AgentsBoardCore --target AgentsBoardServer -c release

# --- Runtime image ---
FROM swift:5.10-noble-slim

RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/.build/release/AgentsBoardServer /usr/local/bin/agentsboard-server

EXPOSE 19850

ENTRYPOINT ["agentsboard-server"]
