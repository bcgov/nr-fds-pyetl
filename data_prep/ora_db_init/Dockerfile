FROM gvenzl/oracle-free:23.7-slim-faststart

#COPY --chown=oracle:oracle --chmod=755 removeDatabase ${ORACLE_BASE}/removeDatabase
COPY --chown=root:root --chmod=755 removeDatabase ${ORACLE_BASE}/removeDatabase

RUN chmod +x ${ORACLE_BASE}/removeDatabase

USER root
RUN usermod -u 1011270000 oracle
USER oracle

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD ["sh", "-c", "${ORACLE_BASE}/healthcheck.sh >/dev/null || exit 1"]

ENTRYPOINT ["container-entrypoint.sh"]