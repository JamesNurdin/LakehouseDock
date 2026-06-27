WITH
  store_sales_agg AS (
    SELECT
      ss_item_sk,
      SUM(ss_quantity) AS store_quantity,
      SUM(ss_net_paid) AS store_net_paid,
      SUM(ss_net_profit) AS store_net_profit
    FROM store_sales
    GROUP BY ss_item_sk
  ),
  web_sales_agg AS (
    SELECT
      ws_item_sk,
      SUM(ws_quantity) AS web_quantity,
      SUM(ws_net_paid) AS web_net_paid,
      SUM(ws_net_profit) AS web_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
  ),
  store_returns_agg AS (
    SELECT
      sr_item_sk,
      SUM(sr_return_quantity) AS store_return_quantity,
      SUM(sr_net_loss) AS store_return_net_loss
    FROM store_returns
    GROUP BY sr_item_sk
  ),
  catalog_returns_agg AS (
    SELECT
      cr_item_sk,
      SUM(cr_return_quantity) AS catalog_return_quantity,
      SUM(cr_net_loss) AS catalog_return_net_loss
    FROM catalog_returns
    GROUP BY cr_item_sk
  ),
  promotion_agg AS (
    SELECT
      p_item_sk,
      SUM(p_cost) AS promotion_total_cost
    FROM promotion
    GROUP BY p_item_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  COALESCE(ss.store_quantity, 0) AS store_quantity,
  COALESCE(ws.web_quantity, 0) AS web_quantity,
  COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
  COALESCE(ss.store_net_paid, 0) + COALESCE(ws.web_net_paid, 0) AS total_net_paid,
  COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_gross_profit,
  COALESCE(sr.store_return_net_loss, 0) + COALESCE(cr.catalog_return_net_loss, 0) AS total_returns_loss,
  COALESCE(p.promotion_total_cost, 0) AS total_promotion_cost,
  (COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0))
    - (COALESCE(sr.store_return_net_loss, 0) + COALESCE(cr.catalog_return_net_loss, 0))
    - COALESCE(p.promotion_total_cost, 0) AS net_profit_after_returns_and_promos
FROM item i
LEFT JOIN store_sales_agg ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN web_sales_agg ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN store_returns_agg sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN catalog_returns_agg cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN promotion_agg p ON p.p_item_sk = i.i_item_sk
ORDER BY net_profit_after_returns_and_promos DESC
LIMIT 100
