"""Enforce one store per district while preserving existing stores."""
from db.database import db


def main():
    conn = db()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT district_name, COUNT(*) FROM store WHERE district_name IS NOT NULL GROUP BY district_name HAVING COUNT(*) > 1")
            if cursor.fetchall():
                raise RuntimeError('Duplicate districts exist; resolve them before migration')
            cursor.execute("SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='store' AND INDEX_NAME='uq_store_district_name'")
            if cursor.fetchone() is None:
                cursor.execute('ALTER TABLE store ADD UNIQUE INDEX uq_store_district_name (district_name)')
        conn.commit()
        print('Unique store district constraint is ready')
    finally:
        conn.close()


if __name__ == '__main__':
    main()
