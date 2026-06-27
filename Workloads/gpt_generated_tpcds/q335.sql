WITH store AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returns
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    GROUP BY d.d_year, ca.ca_state
),
catalog AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(COALESCE(cr.cr_return_amt_inc_tax, 0)) AS total_returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    GROUP BY d.d_year, ca.ca_state
),
web AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    GROUP BY d.d_year, ca.ca_state
)
SELECT
    year,
    state,
    'store'   AS channel,
    total_sales,
    total_returns,
    CASE WHEN total_sales > 0 THEN total_returns / total_sales ELSE NULL END AS return_rate
FROM store
UNION ALL
SELECT
    year,
    state,
    'catalog' AS channel,
    total_sales,
    total_returns,
    CASE WHEN total_sales > 0 THEN total_returns / total_sales ELSE NULL END
FROM catalog
UNION ALL
SELECT
    year,
    state,
    'web'    AS channel,
    total_sales,
    total_returns,
    CASE WHEN total_sales > 0 THEN total_returns / total_sales ELSE NULL END
FROM web
ORDER BY year, state, channel
