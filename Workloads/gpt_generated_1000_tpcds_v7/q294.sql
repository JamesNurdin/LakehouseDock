WITH returns_by_state AS (
    SELECT ca.ca_state AS state,
           SUM(cr.cr_return_amount) AS amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
),
sales_by_state AS (
    SELECT ca.ca_state AS state,
           SUM(ws.ws_net_paid) AS amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
)
SELECT state,
       'return' AS metric,
       amount
FROM returns_by_state
UNION ALL
SELECT state,
       'sale' AS metric,
       amount
FROM sales_by_state
ORDER BY state, metric
