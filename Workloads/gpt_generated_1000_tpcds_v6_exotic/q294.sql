WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ext_ship_cost,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid,
        ws.ws_order_number
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_ship_cost >= 200.00
      AND ws.ws_ext_ship_cost <= 3000.00
      AND ws.ws_ext_discount_amt < 1500.00
      AND ws.ws_net_paid > 0
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
    sm.sm_code,
    sm.sm_type,
    c.c_birth_month,
    COUNT(DISTINCT f.ws_order_number) AS order_cnt,
    SUM(f.ws_net_paid) AS total_net_paid,
    AVG(f.ws_ext_ship_cost) AS avg_ship_cost,
    MIN(f.ws_ext_discount_amt) AS min_discount,
    MAX(f.ws_ext_discount_amt) AS max_discount
FROM filtered_sales f
JOIN tpcds.customer c
    ON f.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.ship_mode sm
    ON f.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_contract = 'A5BYO1qH8HGTTN'
  AND c.c_email_address LIKE '%@org'
  AND c.c_birth_day = 18
GROUP BY sm.sm_code, sm.sm_type, c.c_birth_month
HAVING SUM(f.ws_net_paid) > 50000
ORDER BY total_net_paid DESC
LIMIT 100
