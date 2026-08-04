/*
Goal: Identify high‑value orders that also incurred significant returns, broken down by catalog department, page number, shipping mode, and promotion, showing customer reach and financial metrics.
The query samples sales, joins the six selected tables in a left‑deep chain, applies multiple realistic filters, creates two filtered order‑number sets, intersects them, and then aggregates the intersected orders.
*/
WITH sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    WHERE cs_quantity > 2
      AND cs_net_paid > 100
      AND cs_sold_date_sk BETWEEN 2450000 AND 2450500
),
joined_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cp.cp_department,
        cp.cp_catalog_page_number,
        sm.sm_type,
        p.p_promo_name,
        c.c_customer_id,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk
    FROM sales_sample cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    WHERE cp.cp_department = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND p.p_channel_tv = 'N'
      AND cr.cr_return_amount IS NOT NULL
      AND cr.cr_return_amount > 50
      AND cr.cr_returned_date_sk BETWEEN 2450100 AND 2450200
),
high_profit_orders AS (
    SELECT cs_order_number
    FROM joined_base
    WHERE cs_net_paid > 500
      AND cs_quantity >= 5
),
high_return_orders AS (
    SELECT cs_order_number
    FROM joined_base
    WHERE cr_return_amount > 200
      AND cr_return_quantity >= 2
),
intersect_orders AS (
    SELECT cs_order_number FROM high_profit_orders
    INTERSECT
    SELECT cs_order_number FROM high_return_orders
)
SELECT
    jb.cp_department,
    jb.cp_catalog_page_number,
    jb.sm_type,
    jb.p_promo_name,
    COUNT(DISTINCT jb.c_customer_id) AS distinct_customers,
    SUM(jb.cs_net_paid) AS total_net_paid,
    AVG(jb.cs_quantity) AS avg_quantity,
    MIN(jb.cr_return_amount) AS min_return_amount,
    MAX(jb.cs_net_paid) AS max_net_paid
FROM joined_base jb
JOIN intersect_orders io ON jb.cs_order_number = io.cs_order_number
GROUP BY
    jb.cp_department,
    jb.cp_catalog_page_number,
    jb.sm_type,
    jb.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
