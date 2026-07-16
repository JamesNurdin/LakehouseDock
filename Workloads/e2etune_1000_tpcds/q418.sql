WITH daily_web_page AS (
    SELECT d2.d_date_sk,
           COUNT(DISTINCT wp2.wp_web_page_sk) AS cnt_pages_accessed,
           SUM(wp2.wp_link_count) AS total_links
    FROM web_page wp2
    JOIN date_dim d2 ON wp2.wp_access_date_sk = d2.d_date_sk
    WHERE d2.d_quarter_name = '2000Q1'
    GROUP BY d2.d_date_sk
)
SELECT
    s.s_division_name,
    d.d_day_name,
    t.t_shift,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_net_profit) AS avg_net_profit_per_txn,
    SUM(ss.ss_sales_price) AS total_sales_price,
    SUM(COALESCE(wp.cnt_pages_accessed, 0)) AS total_pages_accessed,
    SUM(COALESCE(wp.total_links, 0)) AS total_links
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN daily_web_page wp ON d.d_date_sk = wp.d_date_sk
WHERE d.d_quarter_name = '2000Q1'
  AND d.d_weekend = 'N'
  AND t.t_shift IN ('Morning', 'Afternoon')
GROUP BY s.s_division_name, d.d_day_name, t.t_shift
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
