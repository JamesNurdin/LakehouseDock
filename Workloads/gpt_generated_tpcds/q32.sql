WITH
    store_sales_agg AS (
        SELECT ss_item_sk AS item_sk,
               sum(ss_net_profit) AS store_sales_profit
        FROM store_sales
        JOIN date_dim d1 ON store_sales.ss_sold_date_sk = d1.d_date_sk
        WHERE d1.d_year = 2001
        GROUP BY ss_item_sk
    ),
    catalog_sales_agg AS (
        SELECT cs_item_sk AS item_sk,
               sum(cs_net_profit) AS catalog_sales_profit
        FROM catalog_sales
        JOIN date_dim d2 ON catalog_sales.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
        GROUP BY cs_item_sk
    ),
    web_sales_agg AS (
        SELECT ws_item_sk AS item_sk,
               sum(ws_net_profit) AS web_sales_profit
        FROM web_sales
        JOIN date_dim d3 ON web_sales.ws_sold_date_sk = d3.d_date_sk
        WHERE d3.d_year = 2001
        GROUP BY ws_item_sk
    ),
    store_returns_agg AS (
        SELECT sr_item_sk AS item_sk,
               sum(sr_net_loss) AS store_return_loss
        FROM store_returns
        JOIN date_dim d4 ON store_returns.sr_returned_date_sk = d4.d_date_sk
        WHERE d4.d_year = 2001
        GROUP BY sr_item_sk
    ),
    catalog_returns_agg AS (
        SELECT cr_item_sk AS item_sk,
               sum(cr_net_loss) AS catalog_return_loss
        FROM catalog_returns
        JOIN date_dim d5 ON catalog_returns.cr_returned_date_sk = d5.d_date_sk
        WHERE d5.d_year = 2001
        GROUP BY cr_item_sk
    ),
    web_returns_agg AS (
        SELECT wr_item_sk AS item_sk,
               sum(wr_net_loss) AS web_return_loss
        FROM web_returns
        JOIN date_dim d6 ON web_returns.wr_returned_date_sk = d6.d_date_sk
        WHERE d6.d_year = 2001
        GROUP BY wr_item_sk
    )
SELECT i.i_item_id,
       i.i_item_desc,
       COALESCE(ss.store_sales_profit, 0)        AS store_sales_profit,
       COALESCE(cs.catalog_sales_profit, 0)      AS catalog_sales_profit,
       COALESCE(ws.web_sales_profit, 0)          AS web_sales_profit,
       COALESCE(sr.store_return_loss, 0)         AS store_return_loss,
       COALESCE(cr.catalog_return_loss, 0)       AS catalog_return_loss,
       COALESCE(wr.web_return_loss, 0)           AS web_return_loss,
       (COALESCE(ss.store_sales_profit, 0) + COALESCE(cs.catalog_sales_profit, 0) + COALESCE(ws.web_sales_profit, 0)
        - COALESCE(sr.store_return_loss, 0) - COALESCE(cr.catalog_return_loss, 0) - COALESCE(wr.web_return_loss, 0))
       AS net_total_profit
FROM item i
LEFT JOIN store_sales_agg ss   ON i.i_item_sk = ss.item_sk
LEFT JOIN catalog_sales_agg cs ON i.i_item_sk = cs.item_sk
LEFT JOIN web_sales_agg ws    ON i.i_item_sk = ws.item_sk
LEFT JOIN store_returns_agg sr ON i.i_item_sk = sr.item_sk
LEFT JOIN catalog_returns_agg cr ON i.i_item_sk = cr.item_sk
LEFT JOIN web_returns_agg wr   ON i.i_item_sk = wr.item_sk
WHERE (COALESCE(ss.store_sales_profit, 0) + COALESCE(cs.catalog_sales_profit, 0) + COALESCE(ws.web_sales_profit, 0)
       - COALESCE(sr.store_return_loss, 0) - COALESCE(cr.catalog_return_loss, 0) - COALESCE(wr.web_return_loss, 0)) <> 0
ORDER BY net_total_profit DESC
LIMIT 100
