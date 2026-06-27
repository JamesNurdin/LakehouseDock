WITH items AS (
    SELECT i_item_sk,
           i_item_id,
           i_category
    FROM item
),
store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_quantity)   AS store_qty
    FROM store_sales ss
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY ss.ss_item_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_net_loss) AS store_loss
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_quantity)   AS catalog_qty
    FROM catalog_sales cs
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY cs.cs_item_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_net_loss) AS catalog_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_quantity)   AS web_qty
    FROM web_sales ws
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY ws.ws_item_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_net_loss) AS web_loss
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
)
SELECT
    i.i_item_id   AS item_id,
    i.i_category  AS category,
    COALESCE(ss.store_profit, 0) + COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0) AS total_profit,
    COALESCE(sr.store_loss, 0)   + COALESCE(cr.catalog_loss, 0)   + COALESCE(wr.web_loss, 0)   AS total_loss,
    (COALESCE(ss.store_profit, 0) + COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0))
    - (COALESCE(sr.store_loss, 0)   + COALESCE(cr.catalog_loss, 0)   + COALESCE(wr.web_loss, 0)) AS net_profit,
    COALESCE(ss.store_qty, 0) + COALESCE(cs.catalog_qty, 0) + COALESCE(ws.web_qty, 0) AS total_quantity
FROM items i
LEFT JOIN store_sales_agg   ss ON i.i_item_sk = ss.item_sk
LEFT JOIN store_returns_agg sr ON i.i_item_sk = sr.item_sk
LEFT JOIN catalog_sales_agg cs ON i.i_item_sk = cs.item_sk
LEFT JOIN catalog_returns_agg cr ON i.i_item_sk = cr.item_sk
LEFT JOIN web_sales_agg     ws ON i.i_item_sk = ws.item_sk
LEFT JOIN web_returns_agg   wr ON i.i_item_sk = wr.item_sk
WHERE (COALESCE(ss.store_profit, 0) + COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0)) > 0
ORDER BY net_profit DESC
LIMIT 10
