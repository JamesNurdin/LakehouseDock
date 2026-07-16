WITH sales_union AS (
  SELECT i.i_item_sk,
         i.i_brand,
         i.i_category,
         cs.cs_net_profit   AS profit,
         cs.cs_quantity     AS qty,
         cs.cs_ext_discount_amt AS discount,
         cs.cs_sold_date_sk AS sold_date_sk
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450825
    AND cs.cs_ext_discount_amt > 500

  UNION ALL

  SELECT i.i_item_sk,
         i.i_brand,
         i.i_category,
         ss.ss_net_profit   AS profit,
         ss.ss_quantity     AS qty,
         ss.ss_ext_discount_amt AS discount,
         ss.ss_sold_date_sk AS sold_date_sk
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450820 AND 2450825
    AND ss.ss_ext_discount_amt > 500

  UNION ALL

  SELECT i.i_item_sk,
         i.i_brand,
         i.i_category,
         ws.ws_net_profit   AS profit,
         ws.ws_quantity     AS qty,
         ws.ws_ext_discount_amt AS discount,
         ws.ws_sold_date_sk AS sold_date_sk
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450820 AND 2450825
    AND ws.ws_ext_discount_amt > 500
    AND wp.wp_type = 'product'
),
inventory_agg AS (
  SELECT inv.inv_item_sk AS i_item_sk,
         AVG(inv.inv_quantity_on_hand) AS avg_inventory
  FROM inventory inv
  WHERE inv.inv_date_sk BETWEEN 2450820 AND 2450825
  GROUP BY inv.inv_item_sk
)
SELECT
  s.i_brand,
  s.i_category,
  SUM(s.profit)          AS total_profit,
  SUM(s.qty)             AS total_quantity,
  AVG(i.avg_inventory)   AS avg_inventory,
  RANK() OVER (ORDER BY SUM(s.profit) DESC) AS profit_rank
FROM sales_union s
LEFT JOIN inventory_agg i ON s.i_item_sk = i.i_item_sk
GROUP BY s.i_brand, s.i_category
ORDER BY total_profit DESC
LIMIT 10
