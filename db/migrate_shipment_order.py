"""Add an optional order ID to shipments; existing rows remain unchanged."""
from db.database import db


def main():
    conn = db()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'shipment' AND COLUMN_NAME = 'purchase_purchase_id'")
            if cursor.fetchone() is None:
                cursor.execute('ALTER TABLE shipment ADD COLUMN purchase_purchase_id VARCHAR(45) NULL')
            else:
                cursor.execute("SELECT CHARACTER_MAXIMUM_LENGTH FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='shipment' AND COLUMN_NAME='purchase_purchase_id'")
                if cursor.fetchone()[0] < 45:
                    cursor.execute('ALTER TABLE shipment MODIFY COLUMN purchase_purchase_id VARCHAR(45) NULL')
        conn.commit()
        print('shipment.purchase_purchase_id is ready')
    finally:
        conn.close()


if __name__ == '__main__':
    main()
