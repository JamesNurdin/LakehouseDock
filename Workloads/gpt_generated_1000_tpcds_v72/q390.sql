WITH
    store_ret AS (
        SELECT
            s.s_state AS state,
            'store_return' AS source,
            SUM(sr.sr_net_loss) AS amount,
            COUNT(*) AS cnt
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY s.s_state
    ),
    web_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            'web_sales' AS source,
            SUM(ws.ws_net_paid_inc_ship) AS amount,
            COUNT(*) AS cnt
        FROM web_sales ws
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY ca.ca_state
    ),
    combined AS (
        SELECT * FROM store_ret
        UNION ALL
        SELECT * FROM web_sales_agg
    )
SELECT
    c.state,
    c.source,
    c.amount,
    c.cnt,
    (
        SELECT MAX(d_date)
        FROM date_dim
        WHERE d_year = 2001
    ) AS max_date_2001
FROM combined c
ORDER BY c.amount DESC
LIMIT 100
