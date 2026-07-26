-- ============================================================================
-- FLOURISH BI — PUBLIC-SCHEMA VIEWS FOR THE LIVE DASHBOARD
-- ============================================================================
-- WHY THIS FILE EXISTS
-- Your dashboard fetches through Supabase's auto-generated REST API
-- (PostgREST), which only exposes the "public" schema by default. Your real
-- numbers live in "bi" (fact_sales, fact_purchases, fact_outstanding, dims)
-- plus a few "public" operational tables. Rather than change Supabase's
-- exposed-schema setting (more moving parts, more to explain in your FYP
-- defense), this file creates thin, read-only VIEWS in "public" that just
-- wrap your existing Sales/Purchasing/Finance/Pricing/Inventory/Collections
-- queries verbatim — one view per chart/KPI card. The dashboard fetches
-- these views directly.
--
-- Run this whole file once in the Supabase SQL editor (Database > SQL Editor)
-- against your project. It only creates views — it does not touch data.
-- Re-run any time you change a query; CREATE OR REPLACE is safe to re-run.
-- ============================================================================

-- ---------- SALES ----------------------------------------------------------
CREATE OR REPLACE VIEW public.v_sales_kpi AS
SELECT
    round(sum(amount))          AS total_sales_pkr,
    count(DISTINCT invoice_id)  AS total_invoices,
    count(DISTINCT customer_id) AS unique_customers,
    round(avg(amount))          AS avg_sale_amount,
    round(sum(net_amount))      AS total_net_sales,
    round(sum(tax_amount))      AS total_tax_collected
FROM bi.fact_sales;

CREATE OR REPLACE VIEW public.v_sales_monthly AS
SELECT
    date_trunc('month', date_key)::date AS month,
    round(sum(amount))                  AS total_sales,
    count(DISTINCT invoice_id)          AS invoices,
    round(avg(amount))                  AS avg_per_invoice
FROM bi.fact_sales
GROUP BY 1
ORDER BY 1;

CREATE OR REPLACE VIEW public.v_sales_top_customers AS
SELECT
    dc.name                       AS customer,
    round(sum(fs.amount))         AS total_sales,
    count(DISTINCT fs.invoice_id) AS invoices,
    round(avg(fs.amount))         AS avg_invoice
FROM bi.fact_sales fs
JOIN bi.dim_customers dc ON dc.id = fs.customer_id
GROUP BY dc.name
ORDER BY total_sales DESC
LIMIT 10;

CREATE OR REPLACE VIEW public.v_sales_payment_terms AS
SELECT
    i.payment_terms,
    count(DISTINCT i.id)    AS invoices,
    round(sum(il.subtotal)) AS total_sales
FROM public.invoices i
JOIN public.invoice_lines il ON il.invoice_id = i.id
WHERE i.status != 'Draft'
GROUP BY i.payment_terms
ORDER BY total_sales DESC;

CREATE OR REPLACE VIEW public.v_sales_delivery_status AS
SELECT
    i.delivery_status,
    count(DISTINCT i.id)    AS invoices,
    round(sum(il.subtotal)) AS total_amount
FROM public.invoices i
JOIN public.invoice_lines il ON il.invoice_id = i.id
WHERE i.status != 'Draft'
GROUP BY i.delivery_status
ORDER BY total_amount DESC;

-- ---------- PURCHASING -------------------------------------------------------
CREATE OR REPLACE VIEW public.v_purchases_monthly AS
SELECT
    date_trunc('month', date_key)::date AS month,
    round(sum(amount))                  AS total_purchases,
    count(DISTINCT bill_id)             AS bills
FROM bi.fact_purchases
GROUP BY 1
ORDER BY 1;

CREATE OR REPLACE VIEW public.v_purchases_top_vendors AS
SELECT
    dv.name                    AS vendor,
    round(sum(fp.amount))      AS total_purchases,
    count(DISTINCT fp.bill_id) AS bills,
    round(avg(fp.amount))      AS avg_bill
FROM bi.fact_purchases fp
JOIN bi.dim_vendors dv ON dv.id = fp.vendor_id
GROUP BY dv.name
ORDER BY total_purchases DESC
LIMIT 10;

-- ---------- FINANCE ----------------------------------------------------------
CREATE OR REPLACE VIEW public.v_ar_aging AS
SELECT age_bucket, count(*) AS invoices, round(sum(amount_due)) AS total_outstanding
FROM bi.fact_outstanding
WHERE entity_type = 'Customer'
GROUP BY age_bucket
ORDER BY min(age_days);

CREATE OR REPLACE VIEW public.v_ap_aging AS
SELECT age_bucket, count(*) AS bills, round(sum(amount_due)) AS total_outstanding
FROM bi.fact_outstanding
WHERE entity_type = 'Vendor'
GROUP BY age_bucket
ORDER BY min(age_days);

CREATE OR REPLACE VIEW public.v_net_position AS
SELECT
    round(sum(amount_due) FILTER (WHERE entity_type='Customer')) AS total_receivable,
    round(sum(amount_due) FILTER (WHERE entity_type='Vendor'))   AS total_payable,
    round(
        sum(amount_due) FILTER (WHERE entity_type='Customer') -
        sum(amount_due) FILTER (WHERE entity_type='Vendor')
    ) AS net_position
FROM bi.fact_outstanding;

-- ---------- PRICING MODEL -----------------------------------------------------
CREATE OR REPLACE VIEW public.v_pricing_by_range AS
SELECT
    CASE
        WHEN unit_price < 50    THEN 'Under 50'
        WHEN unit_price < 100   THEN '50-100'
        WHEN unit_price < 150   THEN '100-150'
        WHEN unit_price < 500   THEN '150-500'
        ELSE 'Above 500'
    END AS price_range,
    count(*)                AS transactions,
    round(avg(unit_price))  AS avg_price,
    round(sum(quantity))    AS total_qty,
    round(sum(subtotal))    AS total_revenue
FROM public.invoice_lines
WHERE unit_price > 0
GROUP BY 1
ORDER BY min(unit_price);

CREATE OR REPLACE VIEW public.v_pricing_by_order_size AS
SELECT
    CASE
        WHEN quantity < 100    THEN 'Small (<100)'
        WHEN quantity < 1000   THEN 'Medium (100-1000)'
        WHEN quantity < 5000   THEN 'Large (1000-5000)'
        ELSE 'Bulk (5000+)'
    END AS order_size,
    count(*)               AS transactions,
    round(avg(unit_price)) AS avg_unit_price,
    round(min(unit_price)) AS min_price,
    round(max(unit_price)) AS max_price
FROM public.invoice_lines
WHERE unit_price > 0
GROUP BY 1
ORDER BY min(quantity);

CREATE OR REPLACE VIEW public.v_pricing_by_terms AS
SELECT
    i.payment_terms,
    count(il.id)               AS transactions,
    round(avg(il.unit_price))  AS avg_unit_price,
    round(min(il.unit_price))  AS min_price,
    round(max(il.unit_price))  AS max_price
FROM public.invoice_lines il
JOIN public.invoices i ON i.id = il.invoice_id
WHERE il.unit_price > 0 AND i.status != 'Draft'
GROUP BY i.payment_terms
ORDER BY avg_unit_price DESC;

-- ---------- INVENTORY ---------------------------------------------------------
CREATE OR REPLACE VIEW public.v_inventory_by_type AS
SELECT type, count(*) AS moves, round(sum(quantity)) AS net_quantity
FROM public.stock_moves
GROUP BY type
ORDER BY net_quantity DESC;

CREATE OR REPLACE VIEW public.v_inventory_monthly AS
SELECT
    date_trunc('month', created_at)::date                AS month,
    round(sum(quantity) FILTER (WHERE type='Purchase'))   AS stock_in,
    round(abs(sum(quantity) FILTER (WHERE type='Sale')))  AS stock_out,
    round(sum(quantity) FILTER (WHERE type='Sale Return'))AS returns
FROM public.stock_moves
GROUP BY 1
ORDER BY 1;

-- ---------- COLLECTIONS --------------------------------------------------------
CREATE OR REPLACE VIEW public.v_collections_top_outstanding AS
SELECT
    dc.name                AS customer,
    round(sum(fo.amount_due)) AS outstanding,
    max(fo.age_days)       AS max_days_overdue,
    count(*)               AS open_invoices
FROM bi.fact_outstanding fo
JOIN bi.dim_customers dc ON dc.id = fo.contact_id
WHERE fo.entity_type = 'Customer'
GROUP BY dc.name
ORDER BY outstanding DESC
LIMIT 10;

-- ---------- HR (missing module — your proposal requires it, schema has it) ----
-- Headcount, active/inactive split, avg tenure, avg salary by department
CREATE OR REPLACE VIEW public.v_hr_kpi AS
SELECT
    count(*) FILTER (WHERE is_active)                              AS active_employees,
    count(*) FILTER (WHERE NOT is_active)                          AS inactive_employees,
    round(avg(salary) FILTER (WHERE is_active))                    AS avg_salary,
    round(avg(EXTRACT(YEAR FROM age(CURRENT_DATE, hire_date))),1)  AS avg_tenure_years,
    count(DISTINCT department_id)                                  AS departments
FROM public.employees;

CREATE OR REPLACE VIEW public.v_hr_headcount_by_dept AS
SELECT
    COALESCE(d.name, e.department, 'Unassigned') AS department,
    count(*) FILTER (WHERE e.is_active)          AS active_employees,
    round(avg(e.salary) FILTER (WHERE e.is_active)) AS avg_salary
FROM public.employees e
LEFT JOIN public.hr_departments d ON d.id = e.department_id
GROUP BY 1
ORDER BY active_employees DESC;

CREATE OR REPLACE VIEW public.v_hr_leave_by_type AS
SELECT
    leave_type,
    count(*)                                             AS requests,
    count(*) FILTER (WHERE status = 'Approved')          AS approved,
    count(*) FILTER (WHERE status = 'Pending')           AS pending,
    count(*) FILTER (WHERE status = 'Rejected')          AS rejected,
    round(avg(end_date - start_date + 1))                AS avg_days
FROM public.hr_leaves
GROUP BY leave_type
ORDER BY requests DESC;

CREATE OR REPLACE VIEW public.v_hr_attendance_monthly AS
SELECT
    date_trunc('month', date)::date                    AS month,
    count(*) FILTER (WHERE status = 'Present')          AS present_days,
    count(*) FILTER (WHERE status = 'Absent')           AS absent_days,
    count(*) FILTER (WHERE status = 'On Leave')         AS on_leave_days,
    round(
        100.0 * count(*) FILTER (WHERE status = 'Present') / NULLIF(count(*), 0), 1
    )                                                    AS attendance_rate_pct
FROM public.attendance
GROUP BY 1
ORDER BY 1;

CREATE OR REPLACE VIEW public.v_hr_payroll_monthly AS
SELECT
    date_trunc('month', period_start)::date AS month,
    count(DISTINCT employee_id)             AS employees_paid,
    round(sum(basic_salary))                AS total_basic,
    round(sum(allowances))                  AS total_allowances,
    round(sum(deductions))                  AS total_deductions,
    round(sum(net_pay))                     AS total_net_pay
FROM public.hr_payslips
WHERE status IN ('Confirmed', 'Paid')
GROUP BY 1
ORDER BY 1;

-- ---------- PIPELINE HEALTH (drives the "last refreshed" badge in the UI) -----
-- bi.status already exists and is written to by bi.refresh_all(); this view
-- just re-exposes it in "public" so PostgREST can serve it without touching
-- your exposed-schemas setting.
CREATE OR REPLACE VIEW public.v_bi_status AS
SELECT id, status, message, last_refresh_at FROM bi.status;

-- ============================================================================
-- GRANTS — PostgREST/Supabase reads as role "anon" (or "authenticated" if you
-- require login). Views need explicit SELECT grants even though the base
-- tables might already have them, because Postgres checks the view's own
-- privileges, not just the underlying tables'.
-- ============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT ON
    public.v_sales_kpi, public.v_sales_monthly, public.v_sales_top_customers,
    public.v_sales_payment_terms, public.v_sales_delivery_status,
    public.v_purchases_monthly, public.v_purchases_top_vendors,
    public.v_ar_aging, public.v_ap_aging, public.v_net_position,
    public.v_pricing_by_range, public.v_pricing_by_order_size, public.v_pricing_by_terms,
    public.v_inventory_by_type, public.v_inventory_monthly,
    public.v_collections_top_outstanding,
    public.v_hr_kpi, public.v_hr_headcount_by_dept, public.v_hr_leave_by_type,
    public.v_hr_attendance_monthly, public.v_hr_payroll_monthly,
    public.v_bi_status
TO anon, authenticated;

-- Let the dashboard's "Refresh" button call the existing wrapper function.
GRANT EXECUTE ON FUNCTION public.refresh_bi_intelligence() TO anon, authenticated;
