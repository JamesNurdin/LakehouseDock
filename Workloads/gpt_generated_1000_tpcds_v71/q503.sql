WITH cs AS (
    SELECT
        w.w_state AS state,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE w.w_city LIKE 'San%'
),
ws AS (
    SELECT
        w.w_state AS state,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE w.w_city LIKE 'San%'
)
SELECT
    state,
    email_domain,
    SUM(net_profit) AS total_profit
FROM (
    SELECT state, email_domain, net_profit FROM cs
    UNION ALL
    SELECT state, email_domain, net_profit FROM ws
) t
GROUP BY GROUPING SETS (
    (state, email_domain),
    (state),
    (email_domain),
    ()
)
ORDER BY
    state,
    email_domain
LIMIT 100
