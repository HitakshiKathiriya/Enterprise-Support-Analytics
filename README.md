# Enterprise Support Analytics & Incident Intelligence Platform

A end-to-end SQL analytics project simulating a real enterprise support operations environment — analyzing **100,000+ support tickets** to uncover SLA violations, recurring incidents, engineer performance, and customer satisfaction trends.

---

## Project Overview

| Detail | Info |
|---|---|
| **Tools Used** | MySQL, Python, Power BI |
| **Dataset Size** | 100,000 tickets, 500 customers, 50 engineers, 20 products, 25,000 feedback rows |
| **Skills Demonstrated** | SQL, CTEs, Window Functions, Stored Procedures, DAX, Data Modeling, Root Cause Analysis |
| **Dashboard Pages** | Executive Overview, Customer Analytics, Engineer Performance, Incident Intelligence |

---

## Business Questions Answered

- What is our overall SLA compliance rate?
- Which products generate the most critical incidents?
- Which engineers resolve tickets fastest?
- Which root causes breach SLA most frequently?
- Which customers are at risk of churning based on CSAT scores?
- How does ticket volume trend month over month?

---

## Dataset

Generated using Python (Faker library) with realistic enterprise distributions.

| Table | Rows | Description |
|---|---|---|
| customers | 500 | Enterprise clients across 8 industries and 8 countries |
| products | 20 | Software products with version numbers |
| support_engineers | 50 | Engineers across 5 support teams |
| tickets | 100,000 | Support incidents with priority, SLA, root cause |
| customer_feedback | 25,000 | Post-resolution CSAT ratings (1-5) |

---

## SQL Phases

### Phase 1 — Database Schema
- Designed 5-table relational schema with foreign key constraints
- Tables: customers, products, support_engineers, tickets, customer_feedback

### Phase 2 — Data Generation
- Generated 100,000+ rows using Python and Faker
- Realistic SLA distributions: 70% compliance, 30% breach
- Weighted CSAT scores and priority distributions

### Phase 3 — Business KPIs
- Total tickets, open vs closed, SLA compliance %
- Average resolution time by priority
- CSAT score, overdue tickets

### Phase 4 — Intermediate SQL
- Multi-table JOINs across all 5 tables
- Top 10 customers by ticket volume
- Industry and subscription plan analysis
- At-risk account identification (CSAT < 3.0)

### Phase 5 — Advanced SQL
- `RANK()`, `DENSE_RANK()`, `LAG()` window functions
- Month-over-month growth with `LAG()`
- Running totals with cumulative `SUM()`
- Nested CTEs for customer health scoring
- Stored procedures: `GetSLAReport()`, `GetEngineerReport()`

### Phase 6 — Root Cause Analysis
- Most common root causes by frequency and priority
- SLA breach rate per root cause
- Recurring incidents — same customer, same root cause
- Root cause impact on CSAT scores
- Executive incident summary with action required flags

---

## Power BI Dashboard

4-page interactive dashboard connected live to MySQL via ODBC.

### Page 1 — Executive Overview
KPIs: Total Tickets, Open Tickets, SLA Compliance %, Avg Resolution Hours, Avg CSAT, SLA Breaches
Charts: Tickets by Status (Donut), Tickets by Priority (Bar), Monthly Trend (Line)

### Page 2 — Customer Analytics
Top 10 customers, Industry breakdown, SLA compliance by subscription plan, CSAT by industry
Slicer: Subscription Plan

### Page 3 — Engineer Performance
Top 15 engineers by tickets resolved, Team comparison, Avg resolution hours by team, CSAT by team
Slicer: Team

### Page 4 — Incident Intelligence
Root cause frequency, Root cause by priority (Stacked), Monthly trend by priority, SLA breaches by root cause
Slicer: Priority

---

## Repository Structure

```
Enterprise-Support-Analytics/
├── Dataset/
│   ├── customers.csv
│   ├── products.csv
│   ├── support_engineers.csv
│   ├── tickets.csv
│   ├── customer_feedback.csv
├── SQL/
│   ├── phase1_schema.sql
│   ├── phase2_direct_insert.py
│   ├── phase3_kpi_queries.sql
│   ├── phase4_intermediate_sql.sql
│   ├── phase5_advanced_sql.sql
│   ├── phase6_root_cause_analysis.sql
├── Dashboard/
│   ├── Enterprise_Support_Analytics_Hitakshi_Kathiriya.pbix
├── ERD/
│   ├── er_diagram.png
├── README.md
```

---

## Key Insights from Analysis

- **SLA Compliance:** 70.08% of closed tickets resolved within SLA
- **Avg CSAT Score:** 3.97 / 5.0
- **Top Root Cause:** API Failure and Network Timeout drive the most incidents
- **At-Risk Accounts:** Customers with CSAT below 3.0 identified for proactive outreach
- **Best Performing Team:** All teams maintain consistent resolution times (~26 hrs avg)

---

## Why This Project

This project directly mirrors my professional experience as a **Technical Support Analyst at Sufalam Solutions**, where I resolved 20–30 enterprise client issues daily, performed root-cause analysis on system failures, and maintained 100% SLA compliance across 50+ accounts.

This analytics platform represents what that operational data would look like when transformed into actionable business intelligence.

---

## Author

**Hitakshi Kathiriya**
Data Science & AI Professional
- LinkedIn: linkedin.com/in/hitakshikathiriya-3088a32ba
- GitHub: github.com/HitakshiKathiriya
- Email: hitakshikathiriya291@gmail.com
