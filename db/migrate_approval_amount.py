"""Add the proposal amount column without changing existing records."""
from db.database import db


def main():
    conn = db()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'approval' AND COLUMN_NAME = 'requested_amount'")
            if cursor.fetchone() is None:
                cursor.execute('ALTER TABLE approval ADD COLUMN requested_amount DECIMAL(18,2) NULL')
        conn.commit()
        print('approval.requested_amount is ready')
    finally:
        conn.close()


if __name__ == '__main__':
    main()
