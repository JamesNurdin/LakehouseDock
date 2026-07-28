WITH bill_side AS (
    SELECT
        ca.ca_state AS cust_state,
        w.w_state AS warehouse_state,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_purchase_estimate >= 8000
      AND ca.ca_state = 'CA'
    GROUP BY ca.ca_state, w.w_state
),
ship_side AS (
    SELECT
        ca.ca_state AS cust_state,
        w.w_state AS warehouse_state,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND cd.cd_dep_college_count = 0
      AND ca.ca_zip LIKE '9%'
    GROUP BY ca.ca_state, w.w_state
)
SELECT cust_state, warehouse_state, total_net_paid
FROM bill_side
UNION ALL
SELECT cust_state, warehouse_state, total_net_paid
FROM ship_side
ORDER BY cust_state, warehouse_state, total_net_paid DESC
