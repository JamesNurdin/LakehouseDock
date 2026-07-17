WITH store_shift_sales AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        td.t_shift,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY ss.ss_store_sk, s.s_store_name, td.t_shift, ss.ss_sold_date_sk
)
SELECT
    ss_store_sk,
    s_store_name,
    t_shift,
    AVG(total_sales) AS avg_daily_sales_per_shift
FROM store_shift_sales
GROUP BY ss_store_sk, s_store_name, t_shift
HAVING AVG(total_sales) > 1000
ORDER BY avg_daily_sales_per_shift DESC
