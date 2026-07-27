WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_order_number,
        ws.ws_ship_mode_sk,
        ws.ws_bill_cdemo_sk
    FROM web_sales ws
    WHERE ws.ws_ship_mode_sk IN (2, 8, 19, 20)
      AND ws.ws_net_paid_inc_ship_tax > 3000
      AND ws.ws_bill_cdemo_sk = 146852
      AND ws.ws_quantity >= 2
)
SELECT
    p.p_promo_name,
    c_bill.c_salutation,
    ca_bill.ca_county,
    COUNT(DISTINCT fs.ws_order_number) AS order_cnt,
    SUM(fs.ws_net_paid) AS total_net_paid,
    AVG(fs.ws_ext_discount_amt) AS avg_discount,
    MIN(fs.ws_net_paid) AS min_net_paid,
    MAX(fs.ws_net_paid) AS max_net_paid
FROM filtered_sales fs
JOIN promotion p
    ON fs.ws_promo_sk = p.p_promo_sk
JOIN customer c_bill
    ON fs.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
    ON fs.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship
    ON fs.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship
    ON fs.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE p.p_discount_active = 'Y'
  AND ca_bill.ca_county = 'York County'
  AND c_bill.c_salutation IN ('Mr.', 'Ms.')
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = p.p_promo_sk
          AND p2.p_cost > 1000
          AND p2.p_promo_name = p.p_promo_name
    )
GROUP BY p.p_promo_name, c_bill.c_salutation, ca_bill.ca_county
HAVING SUM(fs.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
