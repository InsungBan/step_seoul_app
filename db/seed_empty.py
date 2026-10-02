"""Seed only empty tables using the live schema; default rolls back."""
import argparse
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from db.database import db
from db.seed_varied import build_rows


def seed_empty(apply=False):
    today = datetime.now(timezone(timedelta(hours=9))).date()
    rows = build_rows(today)
    rows['employee_operations_state'] = [
        {'scope_id': f'sample:operations:{i}',
         'payload': json.dumps({'sample': True, 'status': status, 'quantity': quantity,
             'amount': amount, 'occurred_at': f'{today} {8+i:02d}:15:00'}, ensure_ascii=False)}
        for i, (status, quantity, amount) in enumerate([
            ('대기', 3, 147000), ('처리중', 8, 552000), ('완료', 12, 948000)])
    ]
    conn = db()
    report = {}
    try:
        conn.begin()
        with conn.cursor() as cur:
            cur.execute('SHOW TABLE STATUS')
            engines = {r[0]: r[1] for r in cur.fetchall()}
            for table, records in rows.items():
                if engines.get(table) != 'InnoDB':
                    raise RuntimeError(f'Unsupported table or engine: {table}')
                cur.execute(f'SELECT COUNT(*) FROM `{table}`')
                before = cur.fetchone()[0]
                if before:
                    report[table] = {'before': before, 'inserted': 0, 'after': before}
                    continue
                cur.execute(f'SHOW COLUMNS FROM `{table}`')
                definitions = cur.fetchall()
                columns = {r[0] for r in definitions}
                required = {r[0] for r in definitions if r[2] == 'NO' and r[4] is None and 'auto_increment' not in r[5]}
                for record in records:
                    if not set(record) <= columns or not required <= set(record):
                        raise RuntimeError(f'Sample does not match live schema: {table}')
                    names = ', '.join(f'`{name}`' for name in record)
                    placeholders = ', '.join('%s' for _ in record)
                    cur.execute(f'INSERT INTO `{table}` ({names}) VALUES ({placeholders})', tuple(record.values()))
                cur.execute(f'SELECT COUNT(*) FROM `{table}`')
                after = cur.fetchone()[0]
                if after != len(records):
                    raise RuntimeError(f'Row count mismatch: {table}')
                report[table] = {'before': before, 'inserted': len(records), 'after': after}
        if apply:
            conn.commit()
        else:
            conn.rollback()
        result = {'committed': apply, 'as_of': str(today), 'tables': report}
        if apply:
            Path(__file__).with_name('seed_empty_report.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
        print(json.dumps(result, ensure_ascii=False, indent=2))
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    seed_empty(parser.parse_args().apply)
