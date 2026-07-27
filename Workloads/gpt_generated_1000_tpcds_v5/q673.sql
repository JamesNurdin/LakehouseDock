WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        CONCAT(s.s_store_name, ' - ', CAST(d.d_year AS VARCHAR)) AS store_year_label,
        REGEXP_EXTRACT(s.s_store_name, '(Mall|Outlet)', 1) AS store_type,
        SUBSTRING(d.d_day_name, 1, 3) AS day_abbrev
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(s.s_store_name, '(?i)mall|outlet')
      AND t.t_meal_time LIKE '%dinner%'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_day_name
)
SELECT
    store_year_label,
    store_type,
    day_abbrev,
    total_profit,
    txn_count
FROM sales_agg
WHERE total_profit > 10000
ORDER BY total_profit DESC
LIMIT 100
