WITH store_sales_agg AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    'store' AS sales_channel,
    SUM(ss.ss_net_paid) AS total_net_paid
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  WHERE i.i_current_price > 100
    AND NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_item_sk = i.i_item_sk
    )
  GROUP BY i.i_item_id, i.i_product_name
),
web_sales_agg AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    'web' AS sales_channel,
    SUM(ws.ws_net_paid) AS total_net_paid
  FROM web_sales ws
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  WHERE i.i_current_price > 100
    AND NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_item_sk = i.i_item_sk
    )
  GROUP BY i.i_item_id, i.i_product_name
)
SELECT
  i_item_id,
  i_product_name,
  sales_channel,
  total_net_paid
FROM (
  SELECT i_item_id, i_product_name, sales_channel, total_net_paid FROM store_sales_agg
  UNION ALL
  SELECT i_item_id, i_product_name, sales_channel, total_net_paid FROM web_sales_agg
) combined
ORDER BY total_net_paid DESC
LIMIT 100
