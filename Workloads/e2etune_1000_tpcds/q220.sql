WITH catalog_agg AS (
  SELECT
    i.i_category AS i_category,
    i.i_class AS i_class,
    hd.hd_buy_potential AS hd_buy_potential,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(cs.cs_quantity) AS catalog_quantity,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customer_cnt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450150
    AND cs.cs_quantity > 30
  GROUP BY i.i_category, i.i_class, hd.hd_buy_potential
),
web_agg AS (
  SELECT
    i.i_category AS i_category,
    i.i_class AS i_class,
    hd.hd_buy_potential AS hd_buy_potential,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ws.ws_quantity) AS web_quantity,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450150
    AND ws.ws_quantity > 30
  GROUP BY i.i_category, i.i_class, hd.hd_buy_potential
),
inventory_agg AS (
  SELECT
    i.i_category AS i_category,
    i.i_class AS i_class,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
  FROM inventory inv
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  GROUP BY i.i_category, i.i_class
)
SELECT
  COALESCE(ca.i_category, wa.i_category) AS i_category,
  COALESCE(ca.i_class, wa.i_class) AS i_class,
  COALESCE(ca.hd_buy_potential, wa.hd_buy_potential) AS hd_buy_potential,
  ca.catalog_net_profit,
  wa.web_net_profit,
  ca.catalog_quantity,
  wa.web_quantity,
  ca.catalog_customer_cnt,
  wa.web_customer_cnt,
  ia.avg_inventory_qty,
  (COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) AS total_net_profit,
  (COALESCE(ca.catalog_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
  ON ca.i_category = wa.i_category
 AND ca.i_class = wa.i_class
 AND ca.hd_buy_potential = wa.hd_buy_potential
LEFT JOIN inventory_agg ia
  ON COALESCE(ca.i_category, wa.i_category) = ia.i_category
 AND COALESCE(ca.i_class, wa.i_class) = ia.i_class
ORDER BY total_net_profit DESC
LIMIT 100
