FROM postgres:17

# Install build dependencies
RUN apt-get update && apt-get install -y \
    postgresql-17-cron \
    git \
    make \
    gcc \
    postgresql-server-dev-17 \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install pg_incremental
RUN git clone https://github.com/crunchydata/pg_incremental.git \
    && cd pg_incremental \
    && make \
    && make install

# Add custom postgresql.conf and pg_hba.conf
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf