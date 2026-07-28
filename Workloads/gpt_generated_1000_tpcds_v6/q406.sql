WITH filtered_items AS (
    SELECT i_item_sk,
           i_product_name
    FROM   item
    WHERE  regexp_like(i_product_name, '[A-Z]{2}[0-9]{2}')
),
filtered_stores AS (
    SELECT s_store_sk,
           s_store_id,
           s_store_name,
           s_city
    FROM   store
    WHERE  s_store_name LIKE 'A%'
      AND  regexp_like(s_city, '^New')
)
SELECT
    fs.s_store_id,
    CONCAT(fs.s_store_name, ' - ', fs.s_city) AS store_full_name,
    SUM(ss.ss_net_profit)                     AS total_profit,
    COUNT(*)                                   AS sales_transactions,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM   store_sales ss
JOIN   filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
JOIN   filtered_stores fs ON ss.ss_store_sk = fs.s_store_sk
JOIN   time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
GROUP BY
    fs.s_store_id,
    fs.s_store_name,
    fs.s_city
ORDER BY total_profit DESC
LIMIT 100
