"""Add an optional refund link without modifying existing return records."""
from db.database import db


def main():
    conn = db()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'return_record' AND COLUMN_NAME = 'refund_refund_id'")
            if cursor.fetchone() is None:
                cursor.execute('ALTER TABLE return_record ADD COLUMN refund_refund_id VARCHAR(45) NULL')
        conn.commit()
        print('return_record.refund_refund_id is ready')
    finally:
        conn.close()


if __name__ == '__main__':
    main()
