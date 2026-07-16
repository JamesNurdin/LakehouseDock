WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_sold_date_sk,
            SUM(ss.ss_ext_sales_price) AS store_sales_amount,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_net_profit) AS store_net_profit
        FROM store_sales ss
        GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
    ),
    catalog_returns_agg AS (
        SELECT
            cr.cr_returned_date_sk,
            SUM(cr.cr_return_amount) AS return_amount,
            SUM(cr.cr_return_quantity) AS return_quantity,
            SUM(cr.cr_net_loss) AS return_net_loss
        FROM catalog_returns cr
        GROUP BY cr.cr_returned_date_sk
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_sold_date_sk,
            SUM(ws.ws_ext_sales_price) AS web_sales_amount,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_net_profit) AS web_net_profit
        FROM web_sales ws
        GROUP BY ws.ws_sold_date_sk
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_date,
    COALESCE(ssa.store_sales_amount, 0)          AS store_sales_amount,
    COALESCE(ssa.store_quantity, 0)              AS store_quantity,
    COALESCE(ssa.store_net_profit, 0)            AS store_net_profit,
    COALESCE(cra.return_amount, 0)               AS return_amount,
    COALESCE(cra.return_quantity, 0)             AS return_quantity,
    COALESCE(cra.return_net_loss, 0)             AS return_net_loss,
    COALESCE(wsa.web_sales_amount, 0)            AS web_sales_amount,
    COALESCE(wsa.web_quantity, 0)                AS web_quantity,
    COALESCE(wsa.web_net_profit, 0)              AS web_net_profit,
    d_closure.d_date                             AS store_closed_date
FROM store s
JOIN store_sales_agg ssa
    ON ssa.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ssa.ss_sold_date_sk = d.d_date_sk
LEFT JOIN catalog_returns_agg cra
    ON cra.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_sales_agg wsa
    ON wsa.ws_sold_date_sk = d.d_date_sk
LEFT JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE d.d_year = 2022
ORDER BY store_sales_amount DESC
LIMIT 100
