WITH ws_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_bill_addr_sk,
        COUNT(*) AS order_cnt,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_ext_wholesale_cost) AS avg_wholesale_cost,
        MIN(ws_ext_sales_price) AS min_sales_price,
        MAX(ws_ext_sales_price) AS max_sales_price
    FROM web_sales
    WHERE
        ws_ext_wholesale_cost > 1000.00
        AND ws_net_paid_inc_tax BETWEEN 2000.00 AND 15000.00
        AND ws_ship_cdemo_sk IN (174439, 193961, 359219)
        AND ws_quantity >= 2
        AND ws_promo_sk IS NOT NULL
    GROUP BY ws_warehouse_sk, ws_bill_addr_sk
    HAVING COUNT(*) >= 5
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    ca_bill.ca_city AS billing_city,
    ca_bill.ca_state AS billing_state,
    ws_agg.order_cnt,
    ws_agg.total_net_paid,
    ws_agg.avg_wholesale_cost,
    ws_agg.min_sales_price,
    ws_agg.max_sales_price,
    (
        SELECT MAX(ws_ext_wholesale_cost)
        FROM web_sales
        WHERE ws_warehouse_sk = w.w_warehouse_sk
    ) AS max_wholesale_cost
FROM ws_agg
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_bill
    ON ws_agg.ws_bill_addr_sk = ca_bill.ca_address_sk
WHERE
    w.w_street_name = 'Center'
    AND w.w_suite_number LIKE 'Suite 3%'
    AND ca_bill.ca_suite_number = 'Suite 80'
    AND ws_agg.total_net_paid > 5000
    AND ca_bill.ca_state = 'TX'
    AND ws_agg.ws_warehouse_sk IN (
        SELECT w1.w_warehouse_sk FROM warehouse w1 WHERE w1.w_city = 'Center'
        UNION
        SELECT w2.w_warehouse_sk FROM warehouse w2 WHERE w2.w_suite_number = 'Suite 350'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        JOIN customer_address ca_ship
            ON ws2.ws_ship_addr_sk = ca_ship.ca_address_sk
        WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
          AND ca_ship.ca_state = 'CA'
    )
ORDER BY ws_agg.total_net_paid DESC
LIMIT 100
