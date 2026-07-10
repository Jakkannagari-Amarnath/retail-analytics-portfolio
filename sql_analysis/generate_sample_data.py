import random
import sqlite3
from datetime import datetime, timedelta

random.seed(42)

# ---- Setup ----
conn = sqlite3.connect("/home/claude/sql_portfolio/retail_sample.db")
cur = conn.cursor()

cur.executescript("""
DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
    invoice_no      TEXT    NOT NULL,
    stock_code      TEXT    NOT NULL,
    description     TEXT,
    quantity        INTEGER NOT NULL,
    invoice_date    TEXT    NOT NULL,
    unit_price      REAL    NOT NULL,
    customer_id     INTEGER,
    country         TEXT    NOT NULL
);
""")

# ---- Reference data ----
products = [
    ("85123A", "WHITE HANGING HEART T-LIGHT HOLDER", 2.55),
    ("71053", "WHITE METAL LANTERN", 3.39),
    ("84406B", "CREAM CUPID HEARTS COAT HANGER", 2.75),
    ("84029G", "KNITTED UNION FLAG HOT WATER BOTTLE", 3.75),
    ("84029E", "RED WOOLLY HOTTIE WHITE HEART", 3.75),
    ("22752", "SET 7 BABUSHKA NESTING BOXES", 7.65),
    ("21730", "GLASS STAR FROSTED T-LIGHT HOLDER", 4.25),
    ("22423", "REGENCY CAKESTAND 3 TIER", 12.75),
    ("21212", "PACK OF 72 RETROSPOT CAKE CASES", 0.55),
    ("22960", "JAM MAKING SET WITH JARS", 4.25),
    ("84879", "ASSORTED COLOUR BIRD ORNAMENT", 1.69),
    ("22138", "BAKING SET 9 PIECE RETROSPOT", 4.95),
    ("48187", "DOORMAT HOME SWEET HOME", 7.08),
    ("23298", "SPACEBOY LUNCH BOX", 1.95),
    ("22086", "PAPER CHAIN KIT 50'S CHRISTMAS", 2.55),
    ("21506", "FANCY FONT BIRTHDAY CARD", 0.42),
    ("22693", "GROW A FLYTRAP OR SUNFLOWER IN TIN", 1.63),
    ("21754", "HOME BUILDING BLOCK WORD", 5.95),
    ("22197", "SMALL POPCORN HOLDER", 0.85),
    ("23203", "JUMBO BAG VINTAGE DOILY", 1.95),
]

countries = (
    ["United Kingdom"] * 70
    + ["Germany"] * 6
    + ["France"] * 6
    + ["EIRE"] * 4
    + ["Spain"] * 3
    + ["Netherlands"] * 3
    + ["Belgium"] * 3
    + ["Portugal"] * 2
    + ["Australia"] * 2
    + ["Italy"] * 1
)

n_customers = 900
customer_ids = list(range(12346, 12346 + n_customers))
customer_country = {cid: random.choice(countries) for cid in customer_ids}

start_date = datetime(2009, 12, 1)
end_date = datetime(2011, 12, 9)
total_days = (end_date - start_date).days

# Give customers different "profiles" so RFM/segmentation queries produce
# meaningfully different segments (champions, regulars, at-risk, lost, one-time)
segments = ["champion", "loyal", "at_risk", "lost", "one_time"]
segment_weights = [0.08, 0.22, 0.20, 0.25, 0.25]
customer_segment = {
    cid: random.choices(segments, weights=segment_weights, k=1)[0]
    for cid in customer_ids
}

def random_date_in_range(days_back_max, days_back_min=0):
    days_back = random.randint(days_back_min, days_back_max)
    d = end_date - timedelta(days=days_back)
    d = d.replace(hour=random.randint(8, 19), minute=random.randint(0, 59))
    return d

rows = []
invoice_counter = 536365

for cid in customer_ids:
    seg = customer_segment[cid]
    if seg == "champion":
        n_orders = random.randint(15, 40)
        days_back_max = 60
    elif seg == "loyal":
        n_orders = random.randint(6, 14)
        days_back_max = 150
    elif seg == "at_risk":
        n_orders = random.randint(3, 8)
        days_back_max = total_days
        days_back_min = 200
    elif seg == "lost":
        n_orders = random.randint(1, 4)
        days_back_max = total_days
        days_back_min = 400
    else:  # one_time
        n_orders = 1
        days_back_max = total_days
        days_back_min = 0

    days_back_min = 0 if seg in ("champion", "loyal") else (200 if seg == "at_risk" else (400 if seg == "lost" else 0))

    for _ in range(n_orders):
        invoice_counter += 1
        invoice_no = str(invoice_counter)
        is_cancellation = random.random() < 0.02
        if is_cancellation:
            invoice_no = "C" + invoice_no

        order_date = random_date_in_range(days_back_max, days_back_min)
        n_lines = random.randint(1, 8)
        country = customer_country[cid]

        for _ in range(n_lines):
            stock_code, desc, base_price = random.choice(products)
            qty = random.randint(1, 20)
            if is_cancellation:
                qty = -abs(qty)
            price = round(base_price * random.uniform(0.9, 1.1), 2)

            rows.append((
                invoice_no,
                stock_code,
                desc,
                qty,
                order_date.strftime("%Y-%m-%d %H:%M:%S"),
                price,
                cid,
                country,
            ))

# Add some transactions with NULL customer_id (guest checkouts), a real feature of the source dataset
for _ in range(500):
    invoice_counter += 1
    order_date = random_date_in_range(total_days, 0)
    stock_code, desc, base_price = random.choice(products)
    rows.append((
        str(invoice_counter),
        stock_code,
        desc,
        random.randint(1, 10),
        order_date.strftime("%Y-%m-%d %H:%M:%S"),
        round(base_price * random.uniform(0.9, 1.1), 2),
        None,
        random.choice(countries),
    ))

cur.executemany(
    "INSERT INTO transactions (invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
    rows,
)
conn.commit()

cur.execute("SELECT COUNT(*), COUNT(DISTINCT customer_id), COUNT(DISTINCT invoice_no) FROM transactions")
print("rows, distinct customers, distinct invoices:", cur.fetchone())

conn.close()
print("Database built: retail_sample.db")
