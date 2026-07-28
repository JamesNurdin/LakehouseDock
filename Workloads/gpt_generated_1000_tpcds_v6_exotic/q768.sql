/*
Goal: Compare 2001 store sales and returns per store, focusing on customers with Gmail addresses and return reasons mentioning "model". The query demonstrates string processing (REGEXP_LIKE, LIKE, CONCAT, SUBSTRING), uses a scalar subquery, an EXISTS filter, a UNION ALL of two aggregated sub‑queries, and applies a HAVING clause to keep only high‑volume stores.
*/
WITH sales AS (
    SELECT
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        MAX(p.p_cost) AS max_promo_cost
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND regexp_like(c.c_email_address, '^.*@gmail\\.com$')
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_net_paid > 1000
      )
    GROUP BY s.s_store_id
),
returns AS (
    SELECT
        s.s_store_id,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(*) AS num_returns,
        MIN(r.r_reason_desc) AS sample_reason
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%model%'
    GROUP BY s.s_store_id
),
union_data AS (
    SELECT s_store_id, total_sales AS metric, 'sales'   AS metric_type FROM sales
    UNION ALL
    SELECT s_store_id, total_returns AS metric, 'returns' AS metric_type FROM returns
)
SELECT
    u.s_store_id,
    MAX(CASE WHEN u.metric_type = 'sales'   THEN u.metric END) AS sales_amount,
    MAX(CASE WHEN u.metric_type = 'returns' THEN u.metric END) AS returns_amount,
    CONCAT('Store ', u.s_store_id)                                 AS store_label,
    SUBSTRING(u.s_store_id, 1, 3)                                 AS store_prefix,
    (SELECT MAX(p_cost) FROM promotion WHERE p_promo_name LIKE '%sale%') AS overall_max_promo_cost
FROM union_data u
GROUP BY u.s_store_id
HAVING MAX(CASE WHEN u.metric_type = 'sales' THEN u.metric END) > 50000
ORDER BY sales_amount DESC
LIMIT 100
