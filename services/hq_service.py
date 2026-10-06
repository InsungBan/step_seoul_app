"""HQ read aggregates. Missing relationships are reported, never guessed."""
from datetime import date, datetime, time, timedelta, timezone
from decimal import Decimal, InvalidOperation

REPORTS = (
    'final-approvals', 'completed-receipts', 'auto-order-targets',
    'monthly-inbound', 'inventory-by-category', 'stock-movements',
    'auto-order-history', 'return-rate',
    'sales-by-category', 'sales-by-store',
)
MISSING = {
    'stock-movements': ['stock_movement: movement_id, shoe_shoe_id, changed_at, quantity_delta, stock_after, reason'],
    'auto-order-history': ['purchase_order.is_auto'],
    'sales-by-store': ['purchase.store_store_id'],
}


def numeric(value):
    try:
        result = Decimal(str(value))
        return result if result.is_finite() else None
    except (InvalidOperation, ValueError):
        return None


def timestamp(value):
    try:
        return datetime.fromisoformat(str(value)).replace(tzinfo=None)
    except ValueError:
        return None


def envelope(rows=None, *, requires=None):
    return {'result': [] if rows is None else rows,
            'available': requires is None, 'requires': requires or []}


def build_reports(data, start=None, end=None, as_of=None):
    today = as_of or datetime.now(timezone(timedelta(hours=9))).date()
    start = start or today.replace(day=1)
    end = end or today
    beginning, ending = datetime.combine(start, time.min), datetime.combine(end + timedelta(days=1), time.min)
    reports = {name: envelope(requires=fields) for name, fields in MISSING.items()}
    proposals = {r['approval_id']: r for r in data.get('approval', [])}
    employees = {r['employee_id']: r for r in data.get('employee', [])}
    grouped = {}
    for row in data.get('approval_process', []):
        if row.get('approval_approval_id') is not None:
            grouped.setdefault(row['approval_approval_id'], []).append(row)
    pending = []
    for ident, versions in grouped.items():
        if len(versions) > 1:
            dates = [timestamp(r.get('processed_at') or r.get('approval_date')) for r in versions]
            if any(d is None for d in dates) or dates.count(max(dates)) != 1:
                continue
            latest = versions[dates.index(max(dates))]
        else:
            latest = versions[0]
        if latest.get('team_leader_approval') in ('승인', '승인완료') and latest.get('director_approval') in ('대기', '결재대기', '미승인') and latest.get('approval_status') in ('결재대기', '결재중', '진행중'):
            pending.append({**latest, **proposals.get(ident, {}), 'employee_name': employees.get(latest.get('employee_employee_id'), {}).get('employee_name')})
    reports['final-approvals'] = envelope(pending)
    reports['completed-receipts'] = envelope([r for r in data.get('receive', []) if r.get('receive_status') == '수령완료'])
    targets = []
    categories = {}
    for shoe in data.get('shoe', []):
        current, standard = numeric(shoe.get('stock_quantity')), numeric(shoe.get('standard_stock'))
        if current is not None and standard is not None and standard > 0 and current <= standard * Decimal('.3'):
            targets.append(shoe)
        category = shoe.get('shoe_category')
        if category and current is not None:
            item = categories.setdefault(category, {'category': category, 'quantity': 0, 'product_count': 0})
            item['quantity'] += current
            item['product_count'] += 1
    reports['auto-order-targets'] = envelope(targets)
    reports['inventory-by-category'] = envelope(list(categories.values()))
    payments = {}
    for row in data.get('payment', []):
        paid_at = timestamp(row.get('payment_date'))
        if numeric(row.get('payment_status')) == 1 and paid_at is not None and beginning <= paid_at < ending:
            payments[row['payment_id']] = row
    shoes = {r['shoe_id']: r for r in data.get('shoe', [])}
    sales = {}
    for purchase in data.get('purchase', []):
        payment = payments.get(purchase.get('payment_id'))
        if payment is None or payment.get('user_user_id') != purchase.get('user_user_id'):
            continue
        shoe = shoes.get(purchase.get('shoe_shoe_id'), {})
        category = shoe.get('shoe_category')
        price, quantity = numeric(purchase.get('sale_price')), numeric(purchase.get('quantity'))
        if category and price is not None and quantity is not None:
            item = sales.setdefault(category, {'category': category, 'amount': 0, 'quantity': 0})
            item['amount'] += price * quantity
            item['quantity'] += quantity
    reports['sales-by-category'] = envelope(sorted(sales.values(), key=lambda r: r['amount'], reverse=True))
    return extend_reports(data, reports, start, end, today)


def extend_reports(data, reports, start, end, today):
    """Activate optional aggregates only when the required DB columns exist."""
    schema = (data.get('_hq_schema') or [{}])[0]
    def has(table, *columns):
        return all(c in schema.get(table, []) for c in columns)
    beginning = datetime.combine(start, time.min)
    ending = datetime.combine(end + timedelta(days=1), time.min)
    def inside(value, lower=beginning, upper=ending):
        d = timestamp(value)
        return d is not None and lower <= d < upper
    month_start = datetime.combine(today.replace(day=1), time.min)
    month_end = datetime.combine(today + timedelta(days=1), time.min)
    inbound = [r for r in data.get('get_order', []) if inside(r.get('get_order_date'), month_start, month_end)]
    quantities = [numeric(r.get('get_order_quantity')) for r in inbound]
    reports['monthly-inbound'] = envelope([{'quantity': sum(quantities), 'basis': 'get_order_date'}]) if all(q is not None for q in quantities) else envelope(requires=['get_order.get_order_quantity'])
    if has('stock_movement', 'movement_id', 'shoe_shoe_id', 'changed_at', 'quantity_delta', 'stock_after', 'reason'):
        lower = datetime.combine(today - timedelta(days=6), time.min)
        upper = datetime.combine(today + timedelta(days=1), time.min)
        moves = [r for r in data.get('stock_movement', []) if inside(r.get('changed_at'), lower, upper)]
        reports['stock-movements'] = envelope(sorted(moves, key=lambda r: r['changed_at'], reverse=True))
    if has('purchase_order', 'is_auto'):
        reports['auto-order-history'] = envelope(sorted([r for r in data.get('purchase_order', []) if numeric(r.get('is_auto')) == 1], key=lambda r: str(r.get('created_at') or r.get('order_date') or ''), reverse=True))
    payments = {r['payment_id']: r for r in data.get('payment', []) if numeric(r.get('payment_status')) == 1 and inside(r.get('payment_date'))}
    paid = [r for r in data.get('purchase', []) if r.get('payment_id') in payments and payments[r['payment_id']].get('user_user_id') == r.get('user_user_id')]
    if has('purchase', 'store_store_id'):
        stores = {r['store_id']: r for r in data.get('store', [])}
        shoes = {r['shoe_id']: r for r in data.get('shoe', [])}
        grouped = {}
        for purchase in paid:
            ident = purchase.get('store_store_id')
            price, quantity = numeric(purchase.get('sale_price')), numeric(purchase.get('quantity'))
            if ident is None or price is None or quantity is None:
                continue
            category = shoes.get(purchase.get('shoe_shoe_id'), {}).get('shoe_category')
            row = grouped.setdefault(ident, {'store_id': ident, 'agency_name': stores.get(ident, {}).get('agency_name'), 'amount': 0, 'quantity': 0, 'categories': {}})
            group = row['categories'].setdefault(category, {'category': category, 'amount': 0, 'quantity': 0})
            group['amount'] += price * quantity
            group['quantity'] += quantity
            row['amount'] += price * quantity
            row['quantity'] += quantity
        ranked = sorted(grouped.values(), key=lambda r: r['amount'], reverse=True)
        for row in ranked:
            row['categories'] = sorted(row['categories'].values(), key=lambda r: r['amount'], reverse=True)
        reports['sales-by-store'] = envelope(ranked)
    returns_in_period = [r for r in data.get('return_record', []) if inside(r.get('return_date'))]
    rate = Decimal(len(returns_in_period)) / Decimal(len(paid)) * 100 if paid else None
    reports['return-rate'] = envelope([{'rate': rate, 'return_count': len(returns_in_period), 'purchase_count': len(paid), 'basis': 'period_transaction_count'}])
    return reports
