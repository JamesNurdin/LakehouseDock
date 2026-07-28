WITH sales_filtered AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_net_profit,
        ss.ss_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND d.d_current_quarter = 'Y'
)
SELECT
    s.s_store_name,
    d.d_quarter_name,
    COUNT(*) AS txn_count,
    SUM(sf.ss_net_profit) AS total_net_profit,
    CONCAT('Store-', SUBSTR(s.s_store_name, 1, 5), '-', d.d_quarter_name) AS store_quarter_key,
    REGEXP_EXTRACT(i.i_item_desc, '(?i)(premium|deluxe)', 1) AS keyword_found
FROM sales_filtered sf
JOIN store s ON sf.ss_store_sk = s.s_store_sk
JOIN date_dim d ON sf.ss_sold_date_sk = d.d_date_sk
JOIN item i ON sf.ss_item_sk = i.i_item_sk
WHERE REGEXP_LIKE(i.i_item_desc, '(?i)premium|deluxe')
  AND s.s_store_name LIKE 'Store %'
GROUP BY
    s.s_store_name,
    d.d_quarter_name,
    CONCAT('Store-', SUBSTR(s.s_store_name, 1, 5), '-', d.d_quarter_name),
    REGEXP_EXTRACT(i.i_item_desc, '(?i)(premium|deluxe)', 1)
ORDER BY total_net_profit DESC
LIMIT 100
