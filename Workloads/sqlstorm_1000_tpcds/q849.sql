WITH sales AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk,
           ss_net_paid,
           ss_net_profit,
           ss_quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_call_center_sk,
           cs_net_paid,
           cs_net_profit,
           cs_quantity,
           'catalog'
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_warehouse_sk,
           ws_net_paid,
           ws_net_profit,
           ws_quantity,
           'web'
    FROM web_sales
)
SELECT d.d_year,
       i.i_category,
       s.channel,
       SUM(s.ss_net_paid) AS total_net_paid,
       SUM(s.ss_net_profit) AS total_net_profit,
       SUM(s.ss_quantity) AS total_quantity
FROM sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
GROUP BY d.d_year, i.i_category, s.channel
ORDER BY d.d_year, i.i_category, s.channel
