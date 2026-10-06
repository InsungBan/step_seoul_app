"""Add a persisted proposal creation date without altering existing records."""
from db.database import db


def main():
    conn = db()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT 1 FROM information_schema.COLUMNS "
                "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'approval' "
                "AND COLUMN_NAME = 'approval_date'"
            )
            if cursor.fetchone() is None:
                cursor.execute('ALTER TABLE approval ADD COLUMN approval_date DATETIME NULL')
        conn.commit()
        print('approval.approval_date is ready')
    finally:
        conn.close()


if __name__ == '__main__':
    main()
