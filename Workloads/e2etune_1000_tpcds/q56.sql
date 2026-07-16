WITH store_sales_agg AS (
    SELECT
        ss.ss_addr_sk AS address_sk,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 20010101 AND 20011231
    GROUP BY ss.ss_addr_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_addr_sk AS address_sk,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20010101 AND 20011231
    GROUP BY ws.ws_bill_addr_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_addr_sk AS address_sk,
        SUM(sr.sr_net_loss) AS store_return_loss
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 20010101 AND 20011231
    GROUP BY sr.sr_addr_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_returning_addr_sk AS address_sk,
        cp.cp_type AS catalog_type,
        SUM(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cr.cr_returned_date_sk BETWEEN 20010101 AND 20011231
    GROUP BY cr.cr_returning_addr_sk, cp.cp_type
)
SELECT
    ca.ca_state AS state,
    cr_agg.catalog_type,
    COALESCE(ss_agg.store_profit, 0) AS store_profit,
    COALESCE(ws_agg.web_profit, 0) AS web_profit,
    COALESCE(sr_agg.store_return_loss, 0) AS store_return_loss,
    COALESCE(cr_agg.catalog_return_loss, 0) AS catalog_return_loss,
    (COALESCE(ss_agg.store_profit, 0) + COALESCE(ws_agg.web_profit, 0) - COALESCE(sr_agg.store_return_loss, 0) - COALESCE(cr_agg.catalog_return_loss, 0)) AS net_profit,
    RANK() OVER (ORDER BY (COALESCE(ss_agg.store_profit, 0) + COALESCE(ws_agg.web_profit, 0) - COALESCE(sr_agg.store_return_loss, 0) - COALESCE(cr_agg.catalog_return_loss, 0)) DESC) AS profit_rank
FROM
    customer_address ca
    LEFT JOIN store_sales_agg ss_agg ON ss_agg.address_sk = ca.ca_address_sk
    LEFT JOIN web_sales_agg ws_agg ON ws_agg.address_sk = ca.ca_address_sk
    LEFT JOIN store_returns_agg sr_agg ON sr_agg.address_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns_agg cr_agg ON cr_agg.address_sk = ca.ca_address_sk
WHERE
    ca.ca_country = 'United States'
    AND (COALESCE(ss_agg.store_profit, 0) + COALESCE(ws_agg.web_profit, 0) - COALESCE(sr_agg.store_return_loss, 0) - COALESCE(cr_agg.catalog_return_loss, 0)) > 0
ORDER BY
    net_profit DESC
LIMIT 100
