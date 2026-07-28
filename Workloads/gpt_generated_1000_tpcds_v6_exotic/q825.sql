WITH store_agg AS (
  SELECT
    i.i_item_sk AS item_sk,
    i.i_product_name AS product_name,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
    AND EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_item_sk = i.i_item_sk
        AND p2.p_discount_active = 'Y'
    )
  GROUP BY i.i_item_sk, i.i_product_name
),
web_agg AS (
  SELECT
    i.i_item_sk AS item_sk,
    i.i_product_name AS product_name,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2451000 AND 2452000
    AND EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_item_sk = i.i_item_sk
        AND p2.p_discount_active = 'Y'
    )
  GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
  combined.item_sk,
  combined.product_name,
  combined.total_profit,
  combined.total_sales,
  combined.total_discount,
  (combined.total_discount / NULLIF(combined.total_sales, 0)) * 100 AS discount_pct
FROM (
  SELECT item_sk, product_name, total_profit, total_sales, total_discount FROM store_agg
  UNION ALL
  SELECT item_sk, product_name, total_profit, total_sales, total_discount FROM web_agg
) AS combined
WHERE combined.total_profit > (
  SELECT AVG(sub.total_profit)
  FROM (
    SELECT total_profit FROM store_agg
    UNION ALL
    SELECT total_profit FROM web_agg
  ) AS sub
)
ORDER BY combined.total_profit DESC
LIMIT 10
