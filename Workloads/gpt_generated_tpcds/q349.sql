WITH
    store_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            d.d_year   AS year,
            SUM(ss.ss_ext_sales_price) AS store_sales_amount,
            SUM(ss.ss_net_profit)      AS store_net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
        GROUP BY ca.ca_state, d.d_year
    ),
    catalog_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            d.d_year   AS year,
            SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
            SUM(cs.cs_net_profit)      AS catalog_net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
        GROUP BY ca.ca_state, d.d_year
    ),
    web_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            d.d_year   AS year,
            SUM(ws.ws_ext_sales_price) AS web_sales_amount,
            SUM(ws.ws_net_profit)      AS web_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
        GROUP BY ca.ca_state, d.d_year
    ),
    store_returns_agg AS (
        SELECT
            ca.ca_state AS state,
            d.d_year   AS year,
            SUM(sr.sr_net_loss) AS store_return_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
        GROUP BY ca.ca_state, d.d_year
    ),
    catalog_returns_agg AS (
        SELECT
            ca.ca_state AS state,
            d.d_year   AS year,
            SUM(cr.cr_net_loss) AS catalog_return_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
        GROUP BY ca.ca_state, d.d_year
    ),
    web_returns_agg AS (
        SELECT
            ca.ca_state AS state,
            d.d_year   AS year,
            SUM(wr.wr_net_loss) AS web_return_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
        GROUP BY ca.ca_state, d.d_year
    )
SELECT
    COALESCE(ss.state, cs.state, ws.state) AS state,
    COALESCE(ss.year, cs.year, ws.year)   AS year,
    COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0) AS total_sales_amount,
    COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
        - COALESCE(sr.store_return_loss, 0) - COALESCE(cr.catalog_return_loss, 0) - COALESCE(wr.web_return_loss, 0) AS total_net_profit,
    CASE
        WHEN (COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0)) = 0 THEN 0
        ELSE (
                COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
                - COALESCE(sr.store_return_loss, 0) - COALESCE(cr.catalog_return_loss, 0) - COALESCE(wr.web_return_loss, 0)
            ) / (COALESCE(ss.store_sales_amount, 0) + COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0))
    END AS net_profit_margin
FROM store_sales_agg ss
FULL OUTER JOIN catalog_sales_agg cs ON ss.state = cs.state AND ss.year = cs.year
FULL OUTER JOIN web_sales_agg ws ON COALESCE(ss.state, cs.state) = ws.state AND COALESCE(ss.year, cs.year) = ws.year
FULL OUTER JOIN store_returns_agg sr ON COALESCE(ss.state, cs.state, ws.state) = sr.state AND COALESCE(ss.year, cs.year, ws.year) = sr.year
FULL OUTER JOIN catalog_returns_agg cr ON COALESCE(ss.state, cs.state, ws.state, sr.state) = cr.state AND COALESCE(ss.year, cs.year, ws.year, sr.year) = cr.year
FULL OUTER JOIN web_returns_agg wr ON COALESCE(ss.state, cs.state, ws.state, sr.state, cr.state) = wr.state AND COALESCE(ss.year, cs.year, ws.year, sr.year, cr.year) = wr.year
ORDER BY total_net_profit DESC
LIMIT 10
