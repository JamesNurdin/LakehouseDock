/*
Goal: Identify top customers for the Electronics department on non‑weekend mornings, combining their store and web sales profitability, and rank them within the department.
*/
WITH
    ss_agg AS (
        SELECT
            ss_customer_sk,
            ss_sold_date_sk,
            ss_sold_time_sk,
            SUM(ss_net_profit)               AS total_store_profit,
            SUM(ss_ext_discount_amt)         AS total_store_discount,
            COUNT(*)                         AS store_sales_cnt
        FROM store_sales
        WHERE ss_ext_discount_amt > 500
        GROUP BY ss_customer_sk, ss_sold_date_sk, ss_sold_time_sk
    ),
    ws_agg AS (
        SELECT
            ws_bill_customer_sk            AS ws_customer_sk,
            ws_sold_date_sk,
            ws_sold_time_sk,
            SUM(ws_net_profit)               AS total_web_profit,
            SUM(ws_ext_discount_amt)         AS total_web_discount,
            COUNT(*)                         AS web_sales_cnt
        FROM web_sales
        WHERE ws_ext_discount_amt > 200
        GROUP BY ws_bill_customer_sk, ws_sold_date_sk, ws_sold_time_sk
    ),
    distinct_cp AS (
        SELECT DISTINCT
            cp_department,
            cp_start_date_sk
        FROM catalog_page
        WHERE cp_department = 'Electronics'
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sales.d_date,
    t.t_hour,
    distinct_cp.cp_department,
    (ss_agg.total_store_profit + COALESCE(ws_agg.total_web_profit, 0)) AS total_combined_profit,
    CASE
        WHEN (ss_agg.total_store_profit + COALESCE(ws_agg.total_web_profit, 0)) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS profit_category,
    ROW_NUMBER() OVER (
        PARTITION BY distinct_cp.cp_department
        ORDER BY (ss_agg.total_store_profit + COALESCE(ws_agg.total_web_profit, 0)) DESC
    ) AS dept_profit_rank
FROM ss_agg
JOIN ws_agg
    ON ss_agg.ss_customer_sk = ws_agg.ws_customer_sk
   AND ss_agg.ss_sold_date_sk = ws_agg.ws_sold_date_sk
   AND ss_agg.ss_sold_time_sk = ws_agg.ws_sold_time_sk
JOIN customer c
    ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN date_dim d_sales
    ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t
    ON ss_agg.ss_sold_time_sk = t.t_time_sk
JOIN distinct_cp
    ON distinct_cp.cp_start_date_sk = d_sales.d_date_sk
WHERE
    d_sales.d_weekend = 'N'
    AND t.t_sub_shift = 'morning'
    AND c.c_birth_year BETWEEN 1960 AND 1980
    AND ss_agg.total_store_discount > 1000
    AND ws_agg.total_web_discount > 500
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sales.d_date,
    t.t_hour,
    distinct_cp.cp_department,
    ss_agg.total_store_profit,
    ws_agg.total_web_profit
HAVING
    (ss_agg.total_store_profit + COALESCE(ws_agg.total_web_profit, 0)) > 0
ORDER BY
    dept_profit_rank,
    total_combined_profit DESC
LIMIT 100
