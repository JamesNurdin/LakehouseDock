WITH catalog_summary AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        'catalog' AS source,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 1000
    GROUP BY sm.sm_type
),
web_summary AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        'web' AS source,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM tpcds.web_returns wr
    JOIN tpcds.web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_order_number = wr.wr_order_number
          AND ws2.ws_quantity > 5
    )
    GROUP BY sm.sm_type
)
SELECT ship_mode_type,
       source,
       total_return_amount
FROM catalog_summary
UNION ALL
SELECT ship_mode_type,
       source,
       total_return_amount
FROM web_summary
ORDER BY total_return_amount DESC, source ASC
LIMIT 100
