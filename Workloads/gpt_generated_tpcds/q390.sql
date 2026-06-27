WITH catalog_sales_agg AS (
  SELECT
    p.p_promo_id AS promo_id,
    cs.cs_quantity AS quantity_sold,
    cs.cs_net_profit AS net_profit
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
),
catalog_returns_agg AS (
  SELECT
    p.p_promo_id AS promo_id,
    cr.cr_return_quantity AS quantity_returned,
    cr.cr_net_loss AS net_loss
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
),
store_sales_agg AS (
  SELECT
    p.p_promo_id AS promo_id,
    ss.ss_quantity AS quantity_sold,
    ss.ss_net_profit AS net_profit
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
store_returns_agg AS (
  SELECT
    p.p_promo_id AS promo_id,
    sr.sr_return_quantity AS quantity_returned,
    sr.sr_net_loss AS net_loss
  FROM store_returns sr
  JOIN store_sales ss
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
web_sales_agg AS (
  SELECT
    p.p_promo_id AS promo_id,
    ws.ws_quantity AS quantity_sold,
    ws.ws_net_profit AS net_profit
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
web_returns_agg AS (
  SELECT
    p.p_promo_id AS promo_id,
    wr.wr_return_quantity AS quantity_returned,
    wr.wr_net_loss AS net_loss
  FROM web_returns wr
  JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
)
SELECT
  promo_id,
  sum(quantity_sold) AS total_quantity_sold,
  sum(quantity_returned) AS total_quantity_returned,
  sum(net_profit) AS total_sales_net_profit,
  sum(net_loss) AS total_returns_net_loss,
  sum(net_profit) - sum(net_loss) AS net_profit_after_returns
FROM (
  SELECT promo_id, quantity_sold, null AS quantity_returned, net_profit, null AS net_loss FROM catalog_sales_agg
  UNION ALL
  SELECT promo_id, null, quantity_returned, null, net_loss FROM catalog_returns_agg
  UNION ALL
  SELECT promo_id, quantity_sold, null, net_profit, null FROM store_sales_agg
  UNION ALL
  SELECT promo_id, null, quantity_returned, null, net_loss FROM store_returns_agg
  UNION ALL
  SELECT promo_id, quantity_sold, null, net_profit, null FROM web_sales_agg
  UNION ALL
  SELECT promo_id, null, quantity_returned, null, net_loss FROM web_returns_agg
) agg
GROUP BY promo_id
ORDER BY net_profit_after_returns DESC
LIMIT 10
