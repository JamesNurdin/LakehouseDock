WITH store_sales_agg AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_category,
           SUM(ss.ss_net_profit)          AS store_net_profit,
           SUM(ss.ss_quantity)            AS store_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category
),
store_returns_agg AS (
    SELECT i.i_item_sk,
           SUM(sr.sr_net_loss)          AS store_return_loss,
           SUM(sr.sr_return_quantity)   AS store_return_quantity
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
    GROUP BY i.i_item_sk
),
catalog_sales_agg AS (
    SELECT i.i_item_sk,
           SUM(cs.cs_net_profit)        AS catalog_net_profit,
           SUM(cs.cs_quantity)          AS catalog_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
    GROUP BY i.i_item_sk
),
catalog_returns_agg AS (
    SELECT i.i_item_sk,
           SUM(cr.cr_net_loss)          AS catalog_return_loss,
           SUM(cr.cr_return_quantity)   AS catalog_return_quantity
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
    GROUP BY i.i_item_sk
),
web_sales_agg AS (
    SELECT i.i_item_sk,
           SUM(ws.ws_net_profit)        AS web_net_profit,
           SUM(ws.ws_quantity)          AS web_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
    GROUP BY i.i_item_sk
),
web_returns_agg AS (
    SELECT i.i_item_sk,
           SUM(wr.wr_net_loss)          AS web_return_loss,
           SUM(wr.wr_return_quantity)   AS web_return_quantity
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
    GROUP BY i.i_item_sk
)
SELECT i.i_item_id,
       i.i_product_name,
       i.i_category,
       COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
       - COALESCE(sr.store_return_loss, 0) - COALESCE(cr.catalog_return_loss, 0) - COALESCE(wr.web_return_loss, 0) AS total_net_profit,
       COALESCE(ss.store_quantity, 0) + COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity_sold,
       COALESCE(sr.store_return_quantity, 0) + COALESCE(cr.catalog_return_quantity, 0) + COALESCE(wr.web_return_quantity, 0) AS total_quantity_returned
FROM item i
LEFT JOIN store_sales_agg   ss ON i.i_item_sk = ss.i_item_sk
LEFT JOIN store_returns_agg sr ON i.i_item_sk = sr.i_item_sk
LEFT JOIN catalog_sales_agg cs ON i.i_item_sk = cs.i_item_sk
LEFT JOIN catalog_returns_agg cr ON i.i_item_sk = cr.i_item_sk
LEFT JOIN web_sales_agg    ws ON i.i_item_sk = ws.i_item_sk
LEFT JOIN web_returns_agg  wr ON i.i_item_sk = wr.i_item_sk
WHERE (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
       - COALESCE(sr.store_return_loss, 0) - COALESCE(cr.catalog_return_loss, 0) - COALESCE(wr.web_return_loss, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 20
