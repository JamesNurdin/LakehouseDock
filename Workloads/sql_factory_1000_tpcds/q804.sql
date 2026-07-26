WITH promo_period AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_cost,
        d_start.d_date AS start_date,
        d_end.d_date AS end_date,
        p.p_discount_active
    FROM promotion p
    LEFT JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    LEFT JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
),
promo_sales AS (
    SELECT
        ss.ss_promo_sk,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(DISTINCT CASE WHEN c.c_preferred_cust_flag = 'Y' THEN ss.ss_customer_sk END) AS preferred_customers,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_promo_sk
),
promo_metrics AS (
    SELECT
        pp.p_promo_sk,
        pp.p_promo_name,
        pp.start_date,
        pp.end_date,
        pp.p_cost,
        ps.distinct_customers,
        ps.preferred_customers,
        ps.total_sales,
        ps.total_discount,
        ps.total_profit,
        CASE WHEN pp.p_cost = 0 THEN NULL ELSE ps.total_sales / pp.p_cost END AS roi
    FROM promo_period pp
    LEFT JOIN promo_sales ps
        ON pp.p_promo_sk = ps.ss_promo_sk
)
SELECT
    pm.p_promo_sk,
    pm.p_promo_name,
    pm.start_date,
    pm.end_date,
    pm.p_cost,
    pm.distinct_customers,
    pm.preferred_customers,
    pm.total_sales,
    pm.total_discount,
    pm.total_profit,
    pm.roi,
    DENSE_RANK() OVER (ORDER BY pm.roi DESC NULLS LAST) AS roi_rank,
    CASE
        WHEN pm.roi > 2 THEN 'Highly Effective'
        WHEN pm.roi BETWEEN 1 AND 2 THEN 'Moderately Effective'
        ELSE 'Low Effectiveness'
    END AS effectiveness_category
FROM promo_metrics pm
ORDER BY roi_rank
LIMIT 20
