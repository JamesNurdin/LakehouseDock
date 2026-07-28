WITH returns_agg AS (
    SELECT
        wr_order_number,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_fee < 5.00
      AND wr_account_credit > 20.00
    GROUP BY wr_order_number
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_coupon_amt) AS avg_coupon,
    MIN(ws.ws_net_paid_inc_ship) AS min_net_paid,
    MAX(ws.ws_net_paid_inc_ship) AS max_net_paid,
    SUM(ws.ws_net_profit) AS total_profit
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns_agg ra
    ON ws.ws_order_number = ra.wr_order_number
WHERE ra.wr_order_number IS NULL
  AND ws.ws_coupon_amt > 100.00
  AND ws.ws_net_paid_inc_ship BETWEEN 500.00 AND 5000.00
  AND c.c_birth_year BETWEEN 1960 AND 1975
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND ws.ws_wholesale_cost < 50.00
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    cd.cd_gender
ORDER BY total_sales DESC
LIMIT 100
