DROP TABLE IF EXISTS spar.ETL_EXECUTION_LOG_HIST;

create table spar.etl_execution_log_hist
( entry_timestamp timestamp(6) not null default current_timestamp
, log_details jsonb not null);

comment on table  spar.ETL_EXECUTION_LOG_HIST is 'ETL Tool monitoring table to store all executed instances of batch processing interfaces';
comment on column spar.ETL_EXECUTION_LOG_HIST.entry_timestamp      		  is 'The timestamp when the record was inserted';
comment on column spar.ETL_EXECUTION_LOG_HIST.log_details       		    is 'JSON document with step statistics';

DROP TABLE IF EXISTS spar.ETL_EXECUTION_LOG;


create table spar.ETL_EXECUTION_LOG(
from_timestamp timestamp not null,
to_timestamp   timestamp not null,
run_status varchar(100) not null,
updated_at  timestamp   default now() not null,
created_at  timestamp   default now() not null
);


comment on table spar.ETL_EXECUTION_LOG is 'ETL Tool monitoring table to store execution current instance of batch processing interfaces';
comment on column spar.ETL_EXECUTION_LOG.from_timestamp             is 'From timestamp for the run (i.e. update_timestamp between from_timestamp and to_timetsamp)';
comment on column spar.ETL_EXECUTION_LOG.to_timestamp               is 'To timestamp for the run (i.e. update_timestamp between from_timestamp and to_timetsamp)';
comment on column spar.ETL_EXECUTION_LOG.run_status                 is 'Status of ETL execution';
comment on column spar.ETL_EXECUTION_LOG.updated_at                 is 'Timestamp of the last time this record was updated';
comment on column spar.ETL_EXECUTION_LOG.created_at                 is 'Timestamp of the time this record was created';
