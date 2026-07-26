# 🌾 Flourish — Enterprise ERP Intelligence & BI Analytics Dashboard

![Supabase](https://img.shields.io/badge/Supabase-Database_%26_REST-emerald?style=flat-square&logo=supabase)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue?style=flat-square&logo=postgresql)
![PostgREST](https://img.shields.io/badge/API-PostgREST_Auto_REST-green?style=flat-square)
![Chart.js](https://img.shields.io/badge/Visualization-Chart.js_4.4-ff6384?style=flat-square&logo=chartdotjs)
![HTML5](https://img.shields.io/badge/Frontend-HTML5_%2F_CSS3_%2F_JS-orange?style=flat-square&logo=html5)

## 📌 Executive Summary
**Flourish ERP Intelligence** is a full-stack **Business Intelligence (BI) & Data Analytics Dashboard** powered by a **PostgreSQL Data Warehouse** hosted on **Supabase**. It transforms raw transactional ERP records into real-time executive Insights across **Sales, Purchasing, Financial AR/AP Aging, Pricing Models, Inventory Management, and HR Analytics**.

The frontend (`index.html`) queries Supabase's auto-generated **PostgREST REST API** endpoints, rendering high-density Chart.js visualizations, KPI drill-downs, and tabular financial summaries.

---

## 🏗️ Data Architecture (Star Schema Data Warehouse)

```
                     +-------------------+
                     |    dim_dates      |
                     +-------------------+
                               |
 +-------------------+         |         +-------------------+
 |   dim_customers   |----+    |    +----|    dim_vendors    |
 +-------------------+    |    |    |    +-------------------+
                          v    v    v
                    +--------------------+
                    |     fact_sales     |
                    |   fact_purchases   |
                    |  fact_outstanding  |
                    +--------------------+
                               ^
                               |
                     +-------------------+
                     |   dim_products    |
                     +-------------------+
```

### 1. Dimension Tables (`datasets/`)
* **`dim_customers`**: Customer profiles, credit limits, payment terms.
* **`dim_products`**: Product catalog, cost pricing, product categories.
* **`dim_vendors`**: Supplier records, lead times, vendor ratings.
* **`dim_dates`**: Fiscal calendar, quarters, months, date keys.
* **`employees` / `hr_departments`**: Headcount, salaries, department mapping.

### 2. Fact Tables (`datasets/`)
* **`fact_sales`**: Sales invoices, line items, net revenue, tax breakdown.
* **`fact_purchases`**: Purchase orders, vendor bills, procurement costs.
* **`fact_outstanding`**: Accounts Receivable (AR) & Accounts Payable (AP) aging invoices.
* **`journal_entries`**: General Ledger accounting transaction entries.
* **`stock_moves`**: Inventory stock-in (purchases), stock-out (sales), and stock returns.

---

## 🐘 PostgreSQL Views & Analytical Queries (`sql/bi_views_for_dashboard.sql`)

All dashboard charts fetch thin, read-only SQL views created in the PostgreSQL database:

### 1. Sales & Revenue Intelligence
* **`v_sales_kpi`**: Aggregate revenue PKR, total invoice count, unique customers, average transaction value.
* **`v_sales_monthly`**: Time-series monthly revenue trends (`date_trunc('month', date_key)`).
* **`v_sales_top_customers`**: Top 10 customer revenue rankings.
* **`v_sales_payment_terms`**: Sales distribution by payment terms (Net 30, Cash on Delivery, Immediate).

### 2. Financial AR/AP & Net Position
* **`v_ar_aging`**: Accounts Receivable aging buckets (Current, 1-30 days, 31-60 days, 60+ days).
* **`v_ap_aging`**: Accounts Payable aging buckets for supplier bills.
* **`v_net_position`**: Live net liquidity calculation (`Total Receivables - Total Payables`).

### 3. Purchasing & Inventory Operations
* **`v_purchases_top_vendors`**: Supplier procurement volume breakdown.
* **`v_inventory_by_type`**: Stock movement distribution (Purchase, Sale, Return).
* **`v_inventory_monthly`**: Monthly Stock-In vs. Stock-Out balance trends.

### 4. HR & Payroll Intelligence
* **`v_hr_kpi`**: Active headcount, turnover, average salary, average tenure years.
* **`v_hr_headcount_by_dept`**: Headcount and compensation by department.
* **`v_hr_payroll_monthly`**: Monthly basic pay, allowances, deductions, and net payroll payouts.

---

## 💻 Interactive Dashboard UI (`index.html`)

* **Custom Dark Theme**: Deep charcoal (`#12181a`) with wheat gold accents (`#d4a72c`).
* **Tabbed Executive Views**: Dedicated tabs for **Sales**, **Purchasing**, **Finance (AR/AP)**, **Pricing Strategy**, **Inventory**, and **HR**.
* **Interactive Drill-Downs**: Clicking any KPI card dynamically swaps chart visualizations and data tables.
* **Live Connection Indicator**: Status pill showing real-time database connection health (`Live`, `Stale`, or `Down`).

---

## 🛠️ Setup & Local Execution

### Option A: Direct Local Preview
1. Open `index.html` directly in **Chrome** or any modern web browser.
2. If connecting to a live Supabase project, set your `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the script configuration block.

### Option B: Database Setup (Supabase / Local PostgreSQL)
1. Run `sql/data_inserts_v2_FINAL.sql` in PostgreSQL / pgAdmin 4 to seed sample data.
2. Run `sql/bi_views_for_dashboard.sql` in the Supabase SQL Editor to generate analytical views and PostgREST security grants.

---

## 📁 Repository Directory Structure

```text
supabase-postgres-bi-dashboard/
├── datasets/                            # Star Schema Datasets (CSVs)
│   ├── dim_customers.csv
│   ├── dim_dates.csv
│   ├── dim_products.csv
│   ├── dim_vendors.csv
│   ├── employees.csv
│   ├── fact_outstanding.csv
│   ├── fact_purchases.csv
│   ├── fact_sales.csv
│   ├── journal_entries.csv
│   └── stock_moves.csv
├── sql/                                 # PostgreSQL Queries & Views
│   ├── bi_views_for_dashboard.sql       # Analytical SQL Views & Security Grants
│   └── data_inserts_v2_FINAL.sql        # Database Seed Data Script
├── index.html                           # Live Interactive Web Dashboard (Chart.js + Supabase)
├── .gitignore
└── README.md                            # Technical Documentation
```

---

## 👨‍💻 Author & Contact
* **Developer**: Business Analytics Graduate & BI Developer
* **Specialization**: Data Warehousing, SQL Analytics, PostgreSQL, Supabase, Dashboard Design
