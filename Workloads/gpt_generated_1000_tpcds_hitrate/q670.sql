WITH
    avg_item_profit AS (
        SELECT cs.cs_item_sk,
               AVG(cs.cs_net_profit) AS avg_profit
        FROM catalog_sales cs
        GROUP BY cs.cs_item_sk
    ),
    sampled_store_sales AS (
        SELECT ss_item_sk,
               ss_quantity,
               ss_ext_sales_price,
               ss_sold_time_sk
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    selected_hours AS (
        SELECT 9 AS hour UNION ALL SELECT 10 UNION ALL SELECT 11
    ),
    top_items AS (
        SELECT i.i_item_id,
               i.i_product_name,
               SUM(ss.ss_ext_sales_price) AS total_sales,
               i.i_item_sk
        FROM sampled_store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE ss.ss_quantity > 1
          AND i.i_item_sk IN (SELECT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_quantity > 5)
        GROUP BY i.i_item_id, i.i_product_name, i.i_item_sk
        HAVING SUM(ss.ss_ext_sales_price) > (SELECT AVG(ss2.ss_ext_sales_price) FROM store_sales ss2)
    ),
    returns_agg AS (
        SELECT i.i_item_id,
               i.i_product_name,
               SUM(sr.sr_return_amt) AS total_returns,
               i.i_item_sk
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE sr.sr_return_quantity > 0
        GROUP BY i.i_item_id, i.i_product_name, i.i_item_sk
    )
SELECT ti.i_item_id,
       ti.i_product_name,
       ti.total_sales AS metric,
       sh.hour,
       'sales' AS source
FROM top_items ti
CROSS JOIN selected_hours sh
WHERE ti.total_sales > (SELECT MAX(avg_profit) FROM avg_item_profit)
UNION ALL
SELECT ra.i_item_id,
       ra.i_product_name,
       ra.total_returns AS metric,
       sh.hour,
       'returns' AS source
FROM returns_agg ra
CROSS JOIN selected_hours sh
ORDER BY metric DESC
LIMIT 100
