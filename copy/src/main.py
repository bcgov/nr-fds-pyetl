"""Entry point for the seedlot copy utility.

Copies a single seedlot (and all of its child tables, recursively) from the
on-prem Oracle ``THE`` schema into the OpenShift Postgres ``spar`` schema.

Usage:
    python src/main.py <seedlot_number> [--overwrite]
"""

from __future__ import annotations

import argparse
import logging
import sys

import copier
import db


def config_logging(verbose: bool) -> None:
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(asctime)s %(levelname)-7s %(name)s: %(message)s",
    )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Copy one seedlot (and all child tables) from Oracle THE to "
            "Postgres spar."
        )
    )
    parser.add_argument(
        "seedlot_number",
        help="The seedlot.seedlot_number to copy.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help=(
            "Delete the seedlot from every target table first, then insert. "
            "Without this flag the tool aborts if the seedlot already exists."
        ),
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable debug logging.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    config_logging(args.verbose)
    logger = logging.getLogger("copy")

    logger.info("Copying seedlot %s (overwrite=%s)", args.seedlot_number, args.overwrite)

    ora_conn = None
    pg_conn = None
    try:
        ora_conn = db.connect_oracle()
        pg_conn = db.connect_postgres()
        counts = copier.copy_seedlot(
            ora_conn=ora_conn,
            pg_conn=pg_conn,
            seedlot_number=args.seedlot_number,
            overwrite=args.overwrite,
        )
        total = sum(counts.values())
        logger.info("Done. Inserted %d row(s) across %d table(s).", total, len(counts))
        return 0
    except copier.SeedlotExistsError as err:
        logger.error(str(err))
        return 2
    except Exception as err:  # noqa: BLE001 - top-level guard
        logger.error("Copy failed (%s): %s", type(err).__name__, err, exc_info=True)
        return 1
    finally:
        if ora_conn is not None:
            ora_conn.close()
        if pg_conn is not None:
            pg_conn.close()


if __name__ == "__main__":
    sys.exit(main())
