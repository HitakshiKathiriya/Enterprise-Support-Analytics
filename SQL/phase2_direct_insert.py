# ============================================================
# ENTERPRISE SUPPORT ANALYTICS
# Phase 2: Direct MySQL Inserter (no CSV import needed)
# Author: Hitakshi Kathiriya
# ============================================================

import random
import mysql.connector
from faker import Faker
from datetime import timedelta, date

fake = Faker()
random.seed(42)

# ============================================================
# CHANGE THESE TO MATCH YOUR MYSQL SETUP
# ============================================================
DB_CONFIG = {
    "host":     "localhost",
    "user":     "root",
    "password": "Hitakshi@0129",   # <-- change this
    "database": "support_analytics"
}

# ============================================================
# REFERENCE DATA
# ============================================================
INDUSTRIES  = ["Banking", "Healthcare", "Retail", "Telecom",
                "Insurance", "Manufacturing", "Education", "Logistics"]
COUNTRIES   = ["USA", "UK", "Canada", "India", "Germany",
                "Australia", "France", "Singapore"]
PLANS       = ["Basic", "Professional", "Enterprise", "Premium"]
TEAMS       = ["Tier-1 Support", "Tier-2 Support",
                "Cloud Ops", "Security", "Database"]
PRODUCT_NAMES = [
    "CloudSync Pro", "DataBridge", "SecureVault", "API Gateway",
    "ReportEngine", "AnalyticsDash", "AutoDeploy", "NetMonitor",
    "QueryBuilder", "LogTracer", "WorkflowAI", "ConnectHub",
    "BackupSuite", "AlertManager", "UserPortal", "PayEngine",
    "CRMLink", "MLPipeline", "StorageGrid", "AuthManager"
]
PRIORITIES  = ["Critical", "High", "Medium", "Low"]
STATUSES    = ["Open", "In Progress", "Closed"]
ROOT_CAUSES = [
    "Database Failure", "Network Timeout", "User Error",
    "Configuration Issue", "API Failure", "Authentication Failure",
    "Memory Overflow", "Permission Denied", "Service Outage",
    "Data Corruption", "Integration Bug", "SSL Certificate Expired"
]
SLA_MAP = {"Critical": 4, "High": 8, "Medium": 24, "Low": 72}

POSITIVE_COMMENTS = [
    "Issue resolved quickly, very satisfied.",
    "Engineer was helpful and professional.",
    "Great support experience!",
    "Fast resolution, no complaints.",
    "Exceeded expectations."
]
NEGATIVE_COMMENTS = [
    "Took too long to resolve.",
    "Had to follow up multiple times.",
    "Not fully satisfied with the fix.",
    "Response was slow.",
    "Issue recurred after resolution."
]

# ============================================================
# CONNECT TO MYSQL
# ============================================================
print("Connecting to MySQL...")
conn   = mysql.connector.connect(**DB_CONFIG)
cursor = conn.cursor()
print("Connected!\n")

# ============================================================
# HELPER: batch insert with progress
# ============================================================
def batch_insert(table, columns, rows, batch_size=1000):
    placeholders = ", ".join(["%s"] * len(columns))
    col_names    = ", ".join(columns)
    sql          = f"INSERT INTO {table} ({col_names}) VALUES ({placeholders})"
    total        = len(rows)
    for i in range(0, total, batch_size):
        batch = rows[i:i + batch_size]
        cursor.executemany(sql, batch)
        conn.commit()
        print(f"  {table}: {min(i + batch_size, total):,} / {total:,} inserted...")

# ============================================================
# 1. CUSTOMERS (500 rows)
# ============================================================
print("Inserting customers...")
customers = [
    (i,
     fake.company(),
     random.choice(INDUSTRIES),
     random.choice(COUNTRIES),
     random.choice(PLANS))
    for i in range(1, 501)
]
batch_insert("customers",
             ["customer_id", "customer_name", "industry", "country", "subscription_plan"],
             customers)

# ============================================================
# 2. PRODUCTS (20 rows)
# ============================================================
print("Inserting products...")
products = [
    (i,
     PRODUCT_NAMES[i - 1],
     f"v{random.randint(1,5)}.{random.randint(0,9)}")
    for i in range(1, 21)
]
batch_insert("products",
             ["product_id", "product_name", "release_version"],
             products)

# ============================================================
# 3. SUPPORT ENGINEERS (50 rows)
# ============================================================
print("Inserting engineers...")
engineers = [
    (i, fake.name(), random.choice(TEAMS))
    for i in range(1, 51)
]
batch_insert("support_engineers",
             ["engineer_id", "engineer_name", "team"],
             engineers)

# ============================================================
# 4. TICKETS (100,000 rows)
# ============================================================
print("Inserting 100,000 tickets...")
start_date = date(2022, 1, 1)
date_range = (date(2024, 12, 31) - start_date).days
tickets    = []

for i in range(1, 100001):
    priority     = random.choice(PRIORITIES)
    sla_hours    = SLA_MAP[priority]
    created_date = start_date + timedelta(days=random.randint(0, date_range))
    status       = random.choices(STATUSES, weights=[15, 20, 65])[0]

    if status == "Closed":
        if random.random() < 0.70:
            resolution_hours = random.randint(1, sla_hours)
        else:
            resolution_hours = sla_hours + random.randint(1, sla_hours * 2)
        resolved_date = created_date + timedelta(hours=resolution_hours)
    else:
        resolution_hours = None
        resolved_date    = None

    tickets.append((
        i,
        random.randint(1, 500),
        random.randint(1, 20),
        random.randint(1, 50),
        priority,
        status,
        created_date,
        resolved_date,
        sla_hours,
        resolution_hours,
        random.choice(ROOT_CAUSES)
    ))

batch_insert("tickets",
             ["ticket_id", "customer_id", "product_id", "engineer_id",
              "priority", "status", "created_date", "resolved_date",
              "sla_hours", "resolution_hours", "root_cause"],
             tickets)

# ============================================================
# 5. CUSTOMER FEEDBACK (25,000 rows)
# ============================================================
print("Inserting feedback...")
closed_ids = [t[0] for t in tickets if t[5] == "Closed"]
sampled    = random.sample(closed_ids, 25000)
feedback   = []

for i, ticket_id in enumerate(sampled, start=1):
    rating  = random.choices([1, 2, 3, 4, 5], weights=[5, 8, 12, 35, 40])[0]
    comment = random.choice(POSITIVE_COMMENTS if rating >= 4 else NEGATIVE_COMMENTS)
    feedback.append((i, ticket_id, rating, comment))

batch_insert("customer_feedback",
             ["feedback_id", "ticket_id", "rating", "comments"],
             feedback)

# ============================================================
# VERIFY
# ============================================================
print("\n" + "=" * 45)
print("  VERIFICATION — Row Counts")
print("=" * 45)
for table, expected in [
    ("customers", 500),
    ("products", 20),
    ("support_engineers", 50),
    ("tickets", 100000),
    ("customer_feedback", 25000)
]:
    cursor.execute(f"SELECT COUNT(*) FROM {table}")
    count = cursor.fetchone()[0]
    status = "OK" if count == expected else "CHECK"
    print(f"  {table:<22} {count:>7,}  [{status}]")

cursor.close()
conn.close()
print("\nDone! All data loaded into MySQL.")
