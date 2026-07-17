WITH sales_item_store AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_profit AS net_profit,
        i.i_product_name,
        s.s_store_name,
        s.s_city,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS store_location,
        SUBSTRING(i.i_product_name, 1, 3) AS product_prefix
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE i.i_product_name LIKE '%CO%'
      AND CONCAT(s.s_store_name, ' - ', s.s_city) LIKE 'A%'
)
SELECT
    store_location,
    product_prefix,
    COUNT(*) AS sales_count,
    SUM(net_profit) AS total_net_profit,
    AVG(net_profit) AS avg_net_profit
FROM sales_item_store
GROUP BY store_location, product_prefix
ORDER BY total_net_profit DESC
LIMIT 10
