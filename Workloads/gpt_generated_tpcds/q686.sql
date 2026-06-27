WITH store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_category
),
store_returns_agg AS (
    SELECT i.i_category,
           SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category
),
catalog_sales_agg AS (
    SELECT i.i_category,
           SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_category
),
catalog_returns_agg AS (
    SELECT i.i_category,
           SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_category
),
web_returns_agg AS (
    SELECT i.i_category,
           SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_category
)
SELECT
    COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category, wr.i_category) AS item_category,
    COALESCE(ss.store_net_profit, 0) - COALESCE(sr.store_net_loss, 0) +
    COALESCE(cs.catalog_net_profit, 0) - COALESCE(cr.catalog_net_loss, 0) +
    COALESCE(ws.web_net_profit, 0) - COALESCE(wr.web_net_loss, 0) AS net_profit_after_returns
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr
  ON ss.i_category = sr.i_category
FULL OUTER JOIN catalog_sales_agg cs
  ON COALESCE(ss.i_category, sr.i_category) = cs.i_category
FULL OUTER JOIN catalog_returns_agg cr
  ON COALESCE(ss.i_category, sr.i_category, cs.i_category) = cr.i_category
FULL OUTER JOIN web_sales_agg ws
  ON COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category) = ws.i_category
FULL OUTER JOIN web_returns_agg wr
  ON COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category) = wr.i_category
ORDER BY net_profit_after_returns DESC
LIMIT 20
