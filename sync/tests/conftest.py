import sys
from pathlib import Path

# The ETL modules are imported as `module.<name>` / `transformations`, which
# means `sync/src` has to be on the path the same way it is at runtime.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
