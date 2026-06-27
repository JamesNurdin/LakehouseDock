WITH unified_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk     AS item_sk,
           cs.cs_net_profit  AS net_profit,
           cs.cs_net_paid    AS net_paid
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk     AS item_sk,
           ss.ss_net_profit  AS net_profit,
           ss.ss_net_paid    AS net_paid
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk     AS item_sk,
           ws.ws_net_profit  AS net_profit,
           ws.ws_net_paid    AS net_paid
    FROM web_sales ws
)
SELECT i.i_category,
       date_dim.d_year,
       date_dim.d_moy                         AS month,
       SUM(us.net_profit)                     AS total_net_profit,
       SUM(us.net_paid)                       AS total_net_paid,
       AVG(inv.inv_quantity_on_hand)          AS avg_inventory_on_hand
FROM unified_sales us
JOIN date_dim
  ON us.date_sk = date_dim.d_date_sk
JOIN item i
  ON us.item_sk = i.i_item_sk
LEFT JOIN inventory inv
  ON inv.inv_date_sk = date_dim.d_date_sk
 AND inv.inv_item_sk = i.i_item_sk
WHERE date_dim.d_year = 2000
GROUP BY i.i_category,
         date_dim.d_year,
         date_dim.d_moy
ORDER BY i.i_category,
         date_dim.d_year,
         date_dim.d_moy
