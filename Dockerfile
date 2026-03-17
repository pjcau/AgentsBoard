FROM swift:6.0-noble AS builder

RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# GRDB requires SQLite with SQLITE_ENABLE_SNAPSHOT.
# Rebuild system SQLite with the flag enabled.
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/* \
    && SQLITE_VERSION="3460100" \
    && SQLITE_YEAR="2024" \
    && wget -q "https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz" \
    || wget -q "https://www.sqlite.org/2025/sqlite-autoconf-3490000.tar.gz" \
    && tar xf sqlite-autoconf-*.tar.gz \
    && cd sqlite-autoconf-* \
    && CFLAGS="-DSQLITE_ENABLE_SNAPSHOT -O2" ./configure --prefix=/usr --disable-static \
    && make -j$(nproc) && make install \
    && cp /usr/lib/libsqlite3.so* /usr/lib/x86_64-linux-gnu/ \
    && cd .. && rm -rf sqlite-autoconf-* && ldconfig

WORKDIR /app
COPY Package.swift Package.resolved* ./
COPY Sources/ Sources/
COPY Tests/ Tests/

# Build Core + Server targets only (no macOS UI)
RUN swift build --target AgentsBoardCore --target AgentsBoardServer -c release

# --- Runtime image ---
FROM swift:6.0-noble-slim

RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/.build/release/AgentsBoardServer /usr/local/bin/agentsboard-server

EXPOSE 19850

ENTRYPOINT ["agentsboard-server"]
