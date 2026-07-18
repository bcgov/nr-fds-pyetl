# seedlot copy (Oracle THE → Postgres spar)

A small standalone utility that **copies a single seedlot** – and all of its
child tables, recursively – from the on-prem Oracle `THE` schema into the
OpenShift Postgres `spar` schema.

It is the reverse direction of the `sync/` tool (which syncs `spar` → `THE`).
The existing sync queries were used to reverse-engineer the column mappings and
transformations here.

## How it works

- All transformations happen **in the Oracle SQL** (one `.sql` file per target
  table). Each query aliases every output column to its exact Postgres column
  name.
- Postgres just does a **straight `INSERT`** built from the Oracle cursor's
  column list.
- The whole copy runs in **one Postgres transaction** – any error rolls the
  entire thing back.
- Driven by a single `seedlot_number` argument.

## Tables copied (in load order)

| # | Postgres target | Source |
|---|-----------------|--------|
| 1 | `spar.seedlot` | `the.seedlot` |
| 2 | `spar.seedlot_orchard` | `the.seedlot` orchard_id / secondary_orchard_id (unpivoted) |
| 3 | `spar.seedlot_collection_method` | `the.seedlot` cone_collection_method codes (unpivoted) |
| 4 | `spar.seedlot_seed_plan_zone` | `the.seedlot_plan_zone` |
| 5 | `spar.seedlot_genetic_worth` | `the.seedlot_genetic_worth` |
| 6 | `spar.seedlot_owner_quantity` | `the.seedlot_owner_quantity` |
| 7 | `spar.seedlot_parent_tree` | `the.seedlot_parent_tree` |
| 8 | `spar.seedlot_parent_tree_gen_qlty` | `the.seedlot_parent_tree_gen_qlty` |
| 9 | `spar.seedlot_parent_tree_smp_mix` | `the.seedlot_parent_tree_smp_mix` |
| 10 | `spar.smp_mix` | `the.smp_mix` |
| 11 | `spar.smp_mix_gen_qlty` | `the.smp_mix_gen_qlty` |

Deletes (on `--overwrite`) run in reverse order to respect foreign keys.

## Usage

```bash
cd copy
# install deps (uv, pip, or poetry - your choice)
pip install -e .

# set connection env vars (see env_sample)
export $(grep -v '^#' env_sample | xargs)

# copy a seedlot
python src/main.py 63001

# overwrite an existing seedlot (deletes all child rows first, then inserts)
python src/main.py 63001 --overwrite

# verbose / debug logging
python src/main.py 63001 -v
```

Exit codes: `0` success, `1` error, `2` seedlot already exists (re-run with
`--overwrite`).

## Configuration

- `src/config/manifest.json` – ordered list of target tables, their query file
  and primary key.
- `src/config/queries/*.sql` – one Oracle `SELECT` per target table. Bind
  variable `:seedlot_number` is supplied by the loader. Edit these to adjust
  column mappings/transformations.

## Transformation notes / assumptions

These mirror (and invert) `sync/config/SQL/SPAR/POSTGRES_SEEDLOT_EXTRACT.sql`:

- **Booleans** – Oracle stores `Y`/`N` chars; Postgres uses `boolean`. Queries
  emit `'true'`/`'false'` text which Postgres casts on insert.
- **User IDs** – Oracle stores `Provider@User`; Postgres stores `Provider\User`.
  Queries do `REPLACE(userid, '@', '\')`.
- **Timestamps** – Oracle stores Pacific local time; Postgres stores UTC. Queries
  convert `America/Los_Angeles → UTC` via
  `FROM_TZ(CAST(ts AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC'`.
  If your Postgres columns are plain `timestamp` (not `timestamptz`) and you want
  wall-clock values preserved instead, drop the conversion.
- **Orchard / cone collection method** – flattened from `the.seedlot` columns
  into separate Postgres child tables.
- **Audit columns** – every `spar` child table has `entry_userid`,
  `entry_timestamp`, `update_userid` and `update_timestamp` as `NOT NULL`
  columns, so each child query populates them (with the same userid/timestamp
  transforms as above).

> ℹ️ **Target schema source.** All target table and column names, types,
> `NOT NULL` constraints and primary keys were confirmed against the
> authoritative SPAR DDL in
> [`bcgov/nr-spar` → `common/init_db/init.sql`](https://github.com/bcgov/nr-spar/blob/main/common/init_db/init.sql).
>
> Two mappings still depend on the **Oracle** (`THE`) side, which is not defined
> in this repo:
> - `spar.seedlot_parent_tree.parent_tree_number` and
>   `spar.smp_mix.parent_tree_number` are `NOT NULL` in Postgres but Oracle stores
>   only `parent_tree_id` on those tables, so the queries `LEFT JOIN the.parent_tree`
>   to resolve the number. Confirm that table/column exists in your Oracle schema.
> - The child-table `entry_*` / `update_*` audit columns are assumed to exist on
>   the corresponding `THE.*` tables. Adjust the `.sql` files if your Oracle
>   schema differs.
