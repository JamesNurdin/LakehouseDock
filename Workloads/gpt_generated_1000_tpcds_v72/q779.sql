WITH web_sales_state AS (
    SELECT
        ca.ca_state AS state,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS orders,
        (
            SELECT AVG(i2.i_current_price)
            FROM web_sales ws2
            JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
            JOIN customer_address ca2 ON ws2.ws_bill_addr_sk = ca2.ca_address_sk
            WHERE ca2.ca_state = ca.ca_state
        ) AS avg_item_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
    HAVING SUM(ws.ws_net_paid) > 1000
)
SELECT
    state,
    total_net_paid AS amount,
    'web_sales' AS source,
    orders,
    avg_item_price
FROM web_sales_state

UNION ALL

SELECT
    ca.ca_state AS state,
    SUM(sr.sr_net_loss) AS amount,
    'store_returns' AS source,
    COUNT(*) AS returns,
    NULL AS avg_item_price
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM store s
        JOIN warehouse w ON w.w_state = s.s_state
        JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE s.s_store_sk = sr.sr_store_sk
          AND s.s_state = ca.ca_state
          AND inv.inv_quantity_on_hand > 0
    )
GROUP BY ca.ca_state
HAVING SUM(sr.sr_net_loss) > 500
LIMIT 100
