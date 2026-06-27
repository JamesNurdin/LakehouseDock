WITH
    catalog_sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq AS month_seq,
            i.i_category,
            SUM(cs.cs_quantity) AS catalog_quantity,
            SUM(cs.cs_net_paid) AS catalog_net_paid,
            SUM(cs.cs_net_profit) AS catalog_net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    web_sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq AS month_seq,
            i.i_category,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_net_paid) AS web_net_paid,
            SUM(ws.ws_net_profit) AS web_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    catalog_returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq AS month_seq,
            i.i_category,
            SUM(cr.cr_return_quantity) AS catalog_return_quantity,
            SUM(cr.cr_net_loss) AS catalog_net_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    store_returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq AS month_seq,
            i.i_category,
            SUM(sr.sr_return_quantity) AS store_return_quantity,
            SUM(sr.sr_net_loss) AS store_net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    )
SELECT
    ca.d_year,
    ca.month_seq,
    ca.i_category,
    ca.catalog_quantity,
    COALESCE(ws.web_quantity, 0) AS web_quantity,
    COALESCE(cr.catalog_return_quantity, 0) AS catalog_return_quantity,
    COALESCE(sr.store_return_quantity, 0) AS store_return_quantity,
    (ca.catalog_quantity + COALESCE(ws.web_quantity, 0)) - (COALESCE(cr.catalog_return_quantity, 0) + COALESCE(sr.store_return_quantity, 0)) AS net_quantity,
    (ca.catalog_net_paid + COALESCE(ws.web_net_paid, 0)) - (COALESCE(cr.catalog_net_loss, 0) + COALESCE(sr.store_net_loss, 0)) AS net_revenue,
    (ca.catalog_net_profit + COALESCE(ws.web_net_profit, 0)) - (COALESCE(cr.catalog_net_loss, 0) + COALESCE(sr.store_net_loss, 0)) AS net_profit_after_returns
FROM catalog_sales_agg ca
LEFT JOIN web_sales_agg ws
    ON ca.d_year = ws.d_year
   AND ca.month_seq = ws.month_seq
   AND ca.i_category = ws.i_category
LEFT JOIN catalog_returns_agg cr
    ON ca.d_year = cr.d_year
   AND ca.month_seq = cr.month_seq
   AND ca.i_category = cr.i_category
LEFT JOIN store_returns_agg sr
    ON ca.d_year = sr.d_year
   AND ca.month_seq = sr.month_seq
   AND ca.i_category = sr.i_category
WHERE ca.d_year = 2001
ORDER BY ca.d_year, ca.month_seq, ca.i_category
