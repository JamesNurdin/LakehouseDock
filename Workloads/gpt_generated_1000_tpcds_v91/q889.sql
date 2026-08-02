WITH sales_items AS (
    SELECT ss.ss_item_sk AS item_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)revolutionary')
    GROUP BY ss.ss_item_sk
),
returned_items AS (
    SELECT cr.cr_item_sk AS item_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)revolutionary')
    GROUP BY cr.cr_item_sk
),
intersect_items AS (
    SELECT item_sk FROM sales_items
    INTERSECT
    SELECT item_sk FROM returned_items
)
SELECT i.i_item_id,
       i.i_product_name,
       si.total_sales,
       si.total_profit,
       CASE
           WHEN si.total_profit > 10000 THEN 'High'
           WHEN si.total_profit > 0 THEN 'Medium'
           ELSE 'Low'
       END AS profit_category,
       CONCAT(i.i_brand, ' ', i.i_category) AS brand_category,
       SUBSTRING(i.i_item_desc, 1, 30) AS short_desc,
       regexp_extract(i.i_item_desc, '(?i)(\\w+)') AS first_word_desc,
       COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
       (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS avg_profit_overall
FROM intersect_items ii
JOIN sales_items si ON si.item_sk = ii.item_sk
JOIN item i ON i.i_item_sk = ii.item_sk
JOIN store_sales ss ON ss.ss_item_sk = ii.item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE c.c_email_address LIKE '%@example.com'
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_item_sk = ii.item_sk
          AND cr.cr_return_amount > 0
    )
GROUP BY i.i_item_id,
         i.i_product_name,
         si.total_sales,
         si.total_profit,
         i.i_brand,
         i.i_category,
         i.i_item_desc
ORDER BY si.total_profit DESC
LIMIT 100
