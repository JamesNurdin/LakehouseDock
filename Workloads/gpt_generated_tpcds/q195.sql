WITH
    store_sales_agg AS (
        SELECT i.i_category AS category,
               SUM(ss.ss_net_profit) AS store_profit,
               SUM(ss.ss_ext_sales_price) AS store_sales_amount
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE d.d_year = 2021
        GROUP BY i.i_category
    ),
    catalog_sales_agg AS (
        SELECT i.i_category AS category,
               SUM(cs.cs_net_profit) AS catalog_profit,
               SUM(cs.cs_ext_sales_price) AS catalog_sales_amount
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE d.d_year = 2021
        GROUP BY i.i_category
    ),
    web_sales_agg AS (
        SELECT i.i_category AS category,
               SUM(ws.ws_net_profit) AS web_profit,
               SUM(ws.ws_ext_sales_price) AS web_sales_amount
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE d.d_year = 2021
        GROUP BY i.i_category
    ),
    store_returns_agg AS (
        SELECT i.i_category AS category,
               SUM(sr.sr_net_loss) AS store_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE d.d_year = 2021
        GROUP BY i.i_category
    ),
    catalog_returns_agg AS (
        SELECT i.i_category AS category,
               SUM(cr.cr_net_loss) AS catalog_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE d.d_year = 2021
        GROUP BY i.i_category
    ),
    web_returns_agg AS (
        SELECT i.i_category AS category,
               SUM(wr.wr_net_loss) AS web_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        WHERE d.d_year = 2021
        GROUP BY i.i_category
    ),
    inventory_agg AS (
        SELECT i.i_category AS category,
               AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        WHERE d.d_year = 2021
        GROUP BY i.i_category
    )
SELECT COALESCE(ss.category, cs.category, ws.category, sr.category, cr.category, wr.category, inv.category) AS category,
       COALESCE(ss.store_profit, 0) + COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0) AS total_profit,
       COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) AS total_sales_amount,
       COALESCE(sr.store_loss, 0) + COALESCE(cr.catalog_loss, 0) + COALESCE(wr.web_loss, 0) AS total_return_loss,
       (COALESCE(ss.store_profit, 0) + COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0)) -
         (COALESCE(sr.store_loss, 0) + COALESCE(cr.catalog_loss, 0) + COALESCE(wr.web_loss, 0)) AS net_profit_after_returns,
       inv.avg_inventory_on_hand
FROM store_sales_agg ss
FULL OUTER JOIN catalog_sales_agg cs ON ss.category = cs.category
FULL OUTER JOIN web_sales_agg ws ON COALESCE(ss.category, cs.category) = ws.category
FULL OUTER JOIN store_returns_agg sr ON COALESCE(ss.category, cs.category, ws.category) = sr.category
FULL OUTER JOIN catalog_returns_agg cr ON COALESCE(ss.category, cs.category, ws.category, sr.category) = cr.category
FULL OUTER JOIN web_returns_agg wr ON COALESCE(ss.category, cs.category, ws.category, sr.category, cr.category) = wr.category
FULL OUTER JOIN inventory_agg inv ON COALESCE(ss.category, cs.category, ws.category, sr.category, cr.category, wr.category) = inv.category
ORDER BY net_profit_after_returns DESC
LIMIT 20
