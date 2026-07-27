/*
Goal: Compute, for each California store, the average daily net paid amount in 2002 for sales made during business hours, filtered by customer birth year and promotion email channel. The query first aggregates sales per store per day (including optional catalog page and web page data via LEFT JOINs), then derives per‑store averages, identifies stores with high sales volume, and returns the top stores ordered by average daily net paid.
*/
WITH daily_store_sales AS (
    SELECT
        s.s_store_id,
        sd.d_date,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim sd ON ss.ss_sold_date_sk = sd.d_date_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = sd.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE sd.d_year = 2002
      AND s.s_state = 'CA'
      AND p.p_channel_email = 'N'
      AND td.t_hour BETWEEN 9 AND 17
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND (cp.cp_type IS NULL OR cp.cp_type = 'Home')
    GROUP BY s.s_store_id, sd.d_date
)
SELECT
    dss.s_store_id,
    AVG(dss.total_net_paid) AS avg_daily_net_paid,
    MAX(dss.total_discount) AS max_daily_discount,
    COUNT(*) AS days_with_sales,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM daily_store_sales d2
            WHERE d2.s_store_id = dss.s_store_id
              AND d2.sales_cnt > 100
        ) THEN 'HIGH_VOLUME'
        ELSE 'NORMAL'
    END AS volume_category
FROM daily_store_sales dss
GROUP BY dss.s_store_id
HAVING AVG(dss.total_net_paid) > 1000
ORDER BY avg_daily_net_paid DESC
LIMIT 100
