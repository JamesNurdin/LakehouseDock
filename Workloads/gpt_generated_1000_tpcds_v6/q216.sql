WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        i.i_item_desc,
        i.i_product_name,
        d.d_year,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '(?i)\\b(ECO|ECONOMY)\\b')
      AND s.s_store_name LIKE '%Market%'
)
SELECT
    CONCAT(s.s_city, ', ', s.s_state) AS city_state,
    s.s_store_name,
    d.d_month_seq AS month_seq,
    SUM(fs.ss_quantity) AS total_quantity,
    SUM(fs.ss_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(fs.ss_net_profit) > 100000 THEN 'High'
        WHEN SUM(fs.ss_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    REGEXP_EXTRACT(i.i_product_name, '(\\d{3,})') AS extracted_number
FROM filtered_sales fs
JOIN date_dim d ON fs.ss_sold_date_sk = d.d_date_sk
JOIN store s ON fs.ss_store_sk = s.s_store_sk
JOIN item i ON fs.ss_item_sk = i.i_item_sk
GROUP BY
    CONCAT(s.s_city, ', ', s.s_state),
    s.s_store_name,
    d.d_month_seq,
    i.i_product_name
ORDER BY total_net_profit DESC
LIMIT 100
