WITH store_sales_agg AS (
    SELECT i.i_category,
           sum(ss.ss_net_paid)   AS store_sales_net_paid,
           sum(ss.ss_net_profit) AS store_sales_net_profit
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_category
),
store_returns_agg AS (
    SELECT i.i_category,
           sum(sr.sr_net_loss) AS store_returns_net_loss
    FROM store_returns sr
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category
),
catalog_sales_agg AS (
    SELECT i.i_category,
           sum(cs.cs_net_paid)   AS catalog_sales_net_paid,
           sum(cs.cs_net_profit) AS catalog_sales_net_profit
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category
),
catalog_returns_agg AS (
    SELECT i.i_category,
           sum(cr.cr_net_loss) AS catalog_returns_net_loss
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           sum(ws.ws_net_paid)   AS web_sales_net_paid,
           sum(ws.ws_net_profit) AS web_sales_net_profit
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_category
),
web_returns_agg AS (
    SELECT i.i_category,
           sum(wr.wr_net_loss) AS web_returns_net_loss
    FROM web_returns wr
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_category
)
SELECT
    COALESCE(ss.i_category, cs.i_category, ws.i_category)                               AS category,
    COALESCE(ss.store_sales_net_paid, 0) + COALESCE(cs.catalog_sales_net_paid, 0) +
    COALESCE(ws.web_sales_net_paid, 0)                                                AS total_sales_net_paid,
    COALESCE(ss.store_sales_net_profit, 0) + COALESCE(cs.catalog_sales_net_profit, 0) +
    COALESCE(ws.web_sales_net_profit, 0)                                             AS total_sales_net_profit,
    COALESCE(sr.store_returns_net_loss, 0) + COALESCE(cr.catalog_returns_net_loss, 0) +
    COALESCE(wr.web_returns_net_loss, 0)                                            AS total_returns_net_loss,
    (COALESCE(ss.store_sales_net_paid, 0) + COALESCE(cs.catalog_sales_net_paid, 0) +
     COALESCE(ws.web_sales_net_paid, 0)) -
    (COALESCE(sr.store_returns_net_loss, 0) + COALESCE(cr.catalog_returns_net_loss, 0) +
     COALESCE(wr.web_returns_net_loss, 0))                                          AS net_revenue
FROM store_sales_agg ss
FULL OUTER JOIN catalog_sales_agg cs
  ON ss.i_category = cs.i_category
FULL OUTER JOIN web_sales_agg ws
  ON COALESCE(ss.i_category, cs.i_category) = ws.i_category
LEFT JOIN store_returns_agg sr
  ON COALESCE(ss.i_category, cs.i_category, ws.i_category) = sr.i_category
LEFT JOIN catalog_returns_agg cr
  ON COALESCE(ss.i_category, cs.i_category, ws.i_category) = cr.i_category
LEFT JOIN web_returns_agg wr
  ON COALESCE(ss.i_category, cs.i_category, ws.i_category) = wr.i_category
ORDER BY net_revenue DESC
LIMIT 10
