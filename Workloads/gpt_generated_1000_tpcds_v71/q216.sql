WITH store_agg AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_profit) AS net_profit,
    'store' AS channel
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv.inv_quantity_on_hand > 0
  )
  GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
  HAVING SUM(ss.ss_net_profit) > 0
),
web_agg AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS net_profit,
    'web' AS channel
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE i.i_color IN (
    SELECT DISTINCT i2.i_color
    FROM item i2
    WHERE i2.i_size = 'large'
  )
  GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
  HAVING SUM(ws.ws_net_profit) > 0
),
combined AS (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
),
ranked AS (
  SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    channel,
    net_profit,
    CASE
      WHEN net_profit >= 10000 THEN 'High'
      WHEN net_profit >= 5000 THEN 'Medium'
      ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY net_profit DESC) AS rank_per_customer
  FROM combined
)
SELECT DISTINCT
  c_customer_id,
  c_first_name,
  c_last_name,
  channel,
  profit_category,
  net_profit,
  rank_per_customer
FROM ranked
WHERE rank_per_customer = 1
ORDER BY net_profit DESC
LIMIT 100
