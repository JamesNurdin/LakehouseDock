WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    CONCAT(s.s_store_name, ' - ', s.s_market_desc) AS store_market,
    i.i_product_name,
    regexp_extract(i.i_item_desc, '(\\d{4})', 1) AS item_code,
    SUBSTRING(i.i_item_desc, 1, 10) AS desc_prefix,
    SUM(fs.ss_net_profit) AS total_net_profit,
    SUM(fs.ss_quantity) AS total_quantity,
    COUNT(*) AS sales_transactions
FROM filtered_sales fs
JOIN store s ON fs.ss_store_sk = s.s_store_sk
JOIN item i ON fs.ss_item_sk = i.i_item_sk
WHERE regexp_like(i.i_item_desc, '\\d{4}')
  AND s.s_market_desc LIKE '%bars%'
GROUP BY
    CONCAT(s.s_store_name, ' - ', s.s_market_desc),
    i.i_product_name,
    regexp_extract(i.i_item_desc, '(\\d{4})', 1),
    SUBSTRING(i.i_item_desc, 1, 10)
ORDER BY total_net_profit DESC
LIMIT 100
