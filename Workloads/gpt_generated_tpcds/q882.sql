WITH
  -- Aggregate store‑sales data per item and promotion
  store_sales_agg AS (
    SELECT
      i.i_item_id   AS item_id,
      p.p_promo_id  AS promo_id,
      SUM(ss.ss_net_paid_inc_tax) AS store_sales_total,
      SUM(ss.ss_net_profit)       AS store_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, p.p_promo_id
  ),
  -- Aggregate store‑return loss per item and promotion (via the sale it belongs to)
  store_returns_agg AS (
    SELECT
      i.i_item_id   AS item_id,
      p.p_promo_id  AS promo_id,
      SUM(sr.sr_net_loss) AS store_returns_loss
    FROM store_returns sr
    JOIN store_sales ss
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk       = ss.ss_item_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, p.p_promo_id
  ),
  -- Aggregate catalog‑sales data per item and promotion
  catalog_sales_agg AS (
    SELECT
      i.i_item_id   AS item_id,
      p.p_promo_id  AS promo_id,
      SUM(cs.cs_net_paid_inc_tax) AS catalog_sales_total,
      SUM(cs.cs_net_profit)       AS catalog_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, p.p_promo_id
  ),
  -- Aggregate catalog‑return loss per item and promotion (via the sale it belongs to)
  catalog_returns_agg AS (
    SELECT
      i.i_item_id   AS item_id,
      p.p_promo_id  AS promo_id,
      SUM(cr.cr_net_loss) AS catalog_returns_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk      = cs.cs_item_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, p.p_promo_id
  ),
  -- Aggregate web‑sales data per item and promotion
  web_sales_agg AS (
    SELECT
      i.i_item_id   AS item_id,
      p.p_promo_id  AS promo_id,
      SUM(ws.ws_net_paid_inc_tax) AS web_sales_total,
      SUM(ws.ws_net_profit)       AS web_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, p.p_promo_id
  ),
  -- Aggregate web‑return loss per item and promotion (via the sale it belongs to)
  web_returns_agg AS (
    SELECT
      i.i_item_id   AS item_id,
      p.p_promo_id  AS promo_id,
      SUM(wr.wr_net_loss) AS web_returns_loss
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk      = ws.ws_item_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, p.p_promo_id
  )
SELECT
  COALESCE(ss.item_id, cs.item_id, ws.item_id)   AS item_id,
  COALESCE(ss.promo_id, cs.promo_id, ws.promo_id) AS promo_id,
  ss.store_sales_total,
  ss.store_profit,
  sr.store_returns_loss,
  cs.catalog_sales_total,
  cs.catalog_profit,
  cr.catalog_returns_loss,
  ws.web_sales_total,
  ws.web_profit,
  wr.web_returns_loss,
  (COALESCE(ss.store_profit, 0) + COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0))
    - (COALESCE(sr.store_returns_loss, 0) + COALESCE(cr.catalog_returns_loss, 0) + COALESCE(wr.web_returns_loss, 0))
    AS net_total_profit
FROM store_sales_agg ss
FULL OUTER JOIN catalog_sales_agg cs
  ON ss.item_id = cs.item_id AND ss.promo_id = cs.promo_id
FULL OUTER JOIN web_sales_agg ws
  ON COALESCE(ss.item_id, cs.item_id) = ws.item_id
     AND COALESCE(ss.promo_id, cs.promo_id) = ws.promo_id
LEFT JOIN store_returns_agg sr
  ON ss.item_id = sr.item_id AND ss.promo_id = sr.promo_id
LEFT JOIN catalog_returns_agg cr
  ON cs.item_id = cr.item_id AND cs.promo_id = cr.promo_id
LEFT JOIN web_returns_agg wr
  ON ws.item_id = wr.item_id AND ws.promo_id = wr.promo_id
ORDER BY net_total_profit DESC
LIMIT 100
