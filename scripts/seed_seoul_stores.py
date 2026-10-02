"""Replace the existing demo stores with one STEP SEOUL store per Seoul district."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from db.database import db


DEMO_STORE_IDS = (
    "demo_st01",
    "demo_st02",
    "demo_st03",
    "demo_st04",
    "demo_st05",
)

# store_id, latitude, longitude, district_name, agency_name, phone
SEOUL_STORES = (
    ("seoul_01", 37.5730, 126.9794, "\uc885\ub85c\uad6c", "STEP \uc885\ub85c \ub300\ub9ac\uc810", "02-2000-0001"),
    ("seoul_02", 37.5636, 126.9976, "\uc911\uad6c", "STEP \uc911\uad6c \ub300\ub9ac\uc810", "02-2000-0002"),
    ("seoul_03", 37.5326, 126.9905, "\uc6a9\uc0b0\uad6c", "STEP \uc6a9\uc0b0 \ub300\ub9ac\uc810", "02-2000-0003"),
    ("seoul_04", 37.5633, 127.0371, "\uc131\ub3d9\uad6c", "STEP \uc131\ub3d9 \ub300\ub9ac\uc810", "02-2000-0004"),
    ("seoul_05", 37.5385, 127.0823, "\uad11\uc9c4\uad6c", "STEP \uad11\uc9c4 \ub300\ub9ac\uc810", "02-2000-0005"),
    ("seoul_06", 37.5744, 127.0396, "\ub3d9\ub300\ubb38\uad6c", "STEP \ub3d9\ub300\ubb38 \ub300\ub9ac\uc810", "02-2000-0006"),
    ("seoul_07", 37.6063, 127.0927, "\uc911\ub791\uad6c", "STEP \uc911\ub791 \ub300\ub9ac\uc810", "02-2000-0007"),
    ("seoul_08", 37.5894, 127.0167, "\uc131\ubd81\uad6c", "STEP \uc131\ubd81 \ub300\ub9ac\uc810", "02-2000-0008"),
    ("seoul_09", 37.6396, 127.0257, "\uac15\ubd81\uad6c", "STEP \uac15\ubd81 \ub300\ub9ac\uc810", "02-2000-0009"),
    ("seoul_10", 37.6688, 127.0471, "\ub3c4\ubd09\uad6c", "STEP \ub3c4\ubd09 \ub300\ub9ac\uc810", "02-2000-0010"),
    ("seoul_11", 37.6542, 127.0568, "\ub178\uc6d0\uad6c", "STEP \ub178\uc6d0 \ub300\ub9ac\uc810", "02-2000-0011"),
    ("seoul_12", 37.6027, 126.9291, "\uc740\ud3c9\uad6c", "STEP \uc740\ud3c9 \ub300\ub9ac\uc810", "02-2000-0012"),
    ("seoul_13", 37.5791, 126.9368, "\uc11c\ub300\ubb38\uad6c", "STEP \uc11c\ub300\ubb38 \ub300\ub9ac\uc810", "02-2000-0013"),
    ("seoul_14", 37.5663, 126.9019, "\ub9c8\ud3ec\uad6c", "STEP \ub9c8\ud3ec \ub300\ub9ac\uc810", "02-2000-0014"),
    ("seoul_15", 37.5170, 126.8665, "\uc591\ucc9c\uad6c", "STEP \uc591\ucc9c \ub300\ub9ac\uc810", "02-2000-0015"),
    ("seoul_16", 37.5509, 126.8495, "\uac15\uc11c\uad6c", "STEP \uac15\uc11c \ub300\ub9ac\uc810", "02-2000-0016"),
    ("seoul_17", 37.4955, 126.8875, "\uad6c\ub85c\uad6c", "STEP \uad6c\ub85c \ub300\ub9ac\uc810", "02-2000-0017"),
    ("seoul_18", 37.4569, 126.8956, "\uae08\ucc9c\uad6c", "STEP \uae08\ucc9c \ub300\ub9ac\uc810", "02-2000-0018"),
    ("seoul_19", 37.5264, 126.8963, "\uc601\ub4f1\ud3ec\uad6c", "STEP \uc601\ub4f1\ud3ec \ub300\ub9ac\uc810", "02-2000-0019"),
    ("seoul_20", 37.5124, 126.9393, "\ub3d9\uc791\uad6c", "STEP \ub3d9\uc791 \ub300\ub9ac\uc810", "02-2000-0020"),
    ("seoul_21", 37.4784, 126.9516, "\uad00\uc545\uad6c", "STEP \uad00\uc545 \ub300\ub9ac\uc810", "02-2000-0021"),
    ("seoul_22", 37.4837, 127.0324, "\uc11c\ucd08\uad6c", "STEP \uc11c\ucd08 \ub300\ub9ac\uc810", "02-2000-0022"),
    ("seoul_23", 37.5172, 127.0473, "\uac15\ub0a8\uad6c", "STEP \uac15\ub0a8 \ub300\ub9ac\uc810", "02-2000-0023"),
    ("seoul_24", 37.5145, 127.1059, "\uc1a1\ud30c\uad6c", "STEP \uc1a1\ud30c \ub300\ub9ac\uc810", "02-2000-0024"),
    ("seoul_25", 37.5301, 127.1238, "\uac15\ub3d9\uad6c", "STEP \uac15\ub3d9 \ub300\ub9ac\uc810", "02-2000-0025"),
)


def main():
    conn = db()
    try:
        with conn.cursor() as cursor:
            placeholders = ", ".join("%s" for _ in DEMO_STORE_IDS)
            for table in ("shipment", "receive", "recall"):
                cursor.execute(
                    f"DELETE FROM `{table}` WHERE `store_store_id` IN ({placeholders})",
                    DEMO_STORE_IDS,
                )
            cursor.execute(
                f"DELETE FROM `store` WHERE `store_id` IN ({placeholders})",
                DEMO_STORE_IDS,
            )
            cursor.executemany(
                """
                INSERT INTO `store`
                    (`store_id`, `latitude`, `longitude`, `district_name`, `agency_name`, `phone`)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                SEOUL_STORES,
            )
        conn.commit()
        print(f"Inserted {len(SEOUL_STORES)} Seoul district stores.")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
