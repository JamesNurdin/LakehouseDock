/*
  Goal: Identify high‑value customers (by total sales) who bought items during PM hours on specific minutes, belong to a "Good" credit rating demographic, and have recent activity. The query joins all four TPC‑DS tables in a left‑deep chain, applies several realistic filter predicates, uses a CTE for the core dataset, intersects two sub‑sets of order numbers to keep only orders that satisfy both quantity and sales thresholds, aggregates sales metrics, filters groups with HAVING, and limits the result to the top 100 rows.
*/
WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sold_time_sk,
        td.t_am_pm,
        td.t_minute,
        td.t_hour,
        c.c_customer_id,
        c.c_last_name,
        c.c_last_review_date,
        cd.cd_credit_rating,
        cd.cd_dep_employed_count,
        cd.cd_dep_count
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_minute IN (10, 12, 14)
      AND c.c_last_name = 'Curtis'
      AND c.c_last_review_date >= 2452500
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_employed_count >= 2
),
intersect_orders AS (
    SELECT cs_order_number
    FROM base_sales
    WHERE cs_quantity >= 5
    INTERSECT
    SELECT cs_order_number
    FROM base_sales
    WHERE cs_ext_sales_price > 5000
)
SELECT
    bs.c_customer_id,
    bs.c_last_name,
    bs.cd_credit_rating,
    bs.t_hour,
    SUM(bs.cs_ext_sales_price) AS total_sales,
    AVG(bs.cs_net_profit) AS avg_profit,
    COUNT(*) AS order_cnt
FROM base_sales bs
JOIN intersect_orders io
    ON bs.cs_order_number = io.cs_order_number
GROUP BY
    bs.c_customer_id,
    bs.c_last_name,
    bs.cd_credit_rating,
    bs.t_hour
HAVING SUM(bs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
