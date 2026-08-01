WITH catalog_branch AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        SUM(cs.cs_net_paid) AS total_sales,
        'catalog' AS source_type
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 5
      AND sm.sm_type = 'EXPRESS'
    GROUP BY c.c_customer_sk, ca.ca_state
),
web_branch AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        SUM(ws.ws_net_paid) AS total_sales,
        'web' AS source_type
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_quantity > 5
      AND sm.sm_type = 'EXPRESS'
    GROUP BY c.c_customer_sk, ca.ca_state
)
SELECT
    u.c_customer_sk,
    u.ca_state,
    u.total_sales,
    u.source_type,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = u.c_customer_sk
          AND wr.wr_return_amt > 0
    ) AS total_refunds
FROM (
    SELECT * FROM catalog_branch
    UNION ALL
    SELECT * FROM web_branch
) u
WHERE (
    SELECT COUNT(*)
    FROM web_returns wr
    WHERE wr.wr_refunded_customer_sk = u.c_customer_sk
) > 0
ORDER BY u.total_sales DESC
LIMIT 100
