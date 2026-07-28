WITH sales_by_store_day AS (
    SELECT
        s.s_store_id,
        d.d_date,
        SUM(cs.cs_net_profit) AS day_profit,
        SUM(cs.cs_ext_sales_price) AS day_sales,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page p ON cs.cs_catalog_page_sk = p.cp_catalog_page_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page w ON w.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_gmt_offset = -5.00
      AND w.wp_link_count > 10
    GROUP BY s.s_store_id, d.d_date
)
SELECT
    s_store_id,
    AVG(day_profit) AS avg_daily_profit,
    SUM(day_sales) AS total_sales
FROM sales_by_store_day
WHERE day_profit > 0
GROUP BY s_store_id
ORDER BY avg_daily_profit DESC
LIMIT 10
