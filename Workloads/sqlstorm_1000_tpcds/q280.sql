WITH unified_sales AS (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_item_sk AS item_sk,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_net_paid,
           cs_net_profit
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_paid,
           ws_net_profit
    FROM web_sales
)
SELECT d.d_year,
       i.i_category,
       SUM(u.net_paid) AS total_net_paid,
       SUM(u.net_profit) AS total_net_profit,
       COUNT(*) AS transaction_cnt,
       AVG(u.net_profit) AS avg_profit_per_tx
FROM unified_sales u
JOIN date_dim d ON u.sold_date_sk = d.d_date_sk
JOIN item i ON u.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, total_net_profit DESC
LIMIT 100
