FROM  ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

# Install the project into `/app`
WORKDIR /app

# install build dependencies
RUN apt update && \
    apt install -y --no-install-recommends \
        gcc \
        libpq-dev \
        python3-dev \
        clang \
        build-essential && \
    useradd -M nonroot

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# COPY src/. /app/
COPY pyproject.toml uv.lock /app/


# required to get the build to work for binary compile of psycopg2
ENV CFLAGS=""
RUN uv sync --frozen --no-install-project --no-dev

# Second stage... copy the venv to final image
FROM  ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS runtime
WORKDIR /app

# Receive build number as argument, retain as environment variable
ARG BUILD_NUMBER
ENV BUILD_NUMBER=${BUILD_NUMBER}

# Install runtime dependencies: postgres client
RUN
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder --chown=root:root --chmod=755 /app/ /app/

RUN apt-get update && \
    apt-get --no-install-recommends install -y \
    postgresql-client \
    && apt-get clean && \
    groupadd -r derek && useradd -r -g derek derek && \
    rm  /app/.venv/bin/python && \
    ln -s $(which python) /app/.venv/bin/python

ENV PATH="/app/.venv/bin:$PATH"
COPY src/. /app/
COPY config/ /app/module/config/
COPY domains/ /app/domains/

# Start the app
RUN chown -R derek:derek /app
USER derek
CMD ["python", "/app/main.py"]
