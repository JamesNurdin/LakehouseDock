WITH
    return_agg AS (
        SELECT
            ca.ca_state,
            SUM(wr.wr_return_amt) AS total_return_amt
        FROM
            web_returns wr
            INNER JOIN customer_address ca
                ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE
            ca.ca_gmt_offset = -8.00
            AND wr.wr_return_amt > 50
        GROUP BY
            ca.ca_state
    ),
    sales_agg AS (
        SELECT
            ca.ca_state,
            SUM(ws.ws_net_paid) AS total_sales_amt
        FROM
            web_sales ws
            INNER JOIN customer_address ca
                ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE
            ws.ws_ext_tax > 20
            AND ca.ca_state IS NOT NULL
        GROUP BY
            ca.ca_state
    )
SELECT
    'Return' AS source_type,
    ca_state,
    total_return_amt AS amount
FROM
    return_agg
UNION ALL
SELECT
    'Sale' AS source_type,
    ca_state,
    total_sales_amt AS amount
FROM
    sales_agg
ORDER BY
    source_type,
    amount DESC
LIMIT 100
