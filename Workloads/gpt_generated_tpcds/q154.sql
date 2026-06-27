/* Net profit by product category and month (year 2001) across all sales channels */
WITH sales_union AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_net_profit AS net_profit
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           ws_net_profit AS net_profit
    FROM web_sales
)
SELECT d.d_year,
       d.d_moy,
       i.i_category,
       SUM(su.net_profit) AS total_net_profit,
       COUNT(DISTINCT su.item_sk) AS distinct_items_sold
FROM sales_union su
JOIN date_dim d ON su.date_sk = d.d_date_sk
JOIN item i ON su.item_sk = i.i_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_year,
         d.d_moy,
         i.i_category
ORDER BY d.d_year,
         d.d_moy,
         i.i_category
