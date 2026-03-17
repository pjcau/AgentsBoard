FROM swift:6.0-noble AS builder

RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# GRDB requires SQLite with SQLITE_ENABLE_SNAPSHOT.
# Rebuild system SQLite with the flag enabled.
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/* \
    && wget -q "https://www.sqlite.org/2024/sqlite-autoconf-3460100.tar.gz" \
    && tar xf sqlite-autoconf-3460100.tar.gz \
    && cd sqlite-autoconf-3460100 \
    && CFLAGS="-DSQLITE_ENABLE_SNAPSHOT -O2" \
       ./configure --prefix=/usr --libdir=/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH) --disable-static \
    && make -j$(nproc) && make install \
    && cd .. && rm -rf sqlite-autoconf-* && ldconfig

WORKDIR /app
COPY Package.swift Package.resolved* ./
COPY Sources/ Sources/
COPY Tests/ Tests/

# Build Server product (produces linked binary)
RUN swift build --product AgentsBoardServer -c release

# --- Runtime image ---
FROM swift:6.0-noble-slim

RUN apt-get update && apt-get install -y libsqlite3-0 && rm -rf /var/lib/apt/lists/*

# Copy the custom sqlite3 from builder (with SQLITE_ENABLE_SNAPSHOT)
COPY --from=builder /usr/lib/*-linux-gnu/libsqlite3* /usr/lib/

WORKDIR /app
# Binary path includes architecture triple on Linux
COPY --from=builder /app/.build/*-unknown-linux-gnu/release/AgentsBoardServer /usr/local/bin/agentsboard-server

EXPOSE 19850

ENV AGENTSBOARD_HOST=0.0.0.0

ENTRYPOINT ["agentsboard-server"]
