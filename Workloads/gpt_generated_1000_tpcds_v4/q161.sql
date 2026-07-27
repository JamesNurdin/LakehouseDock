WITH ws_agg AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_sales_price > 20.00
      AND ws_ext_list_price BETWEEN 1000.00 AND 5000.00
      AND ws_ship_mode_sk IN (1, 2, 3)
      AND ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws_quantity >= 2
    GROUP BY ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_location_type,
    ws_agg.total_sales,
    ws_agg.total_profit,
    ws_agg.order_cnt,
    ws_agg.avg_sales_price
FROM ws_agg
JOIN customer c
    ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_birth_month = 6
  AND c.c_email_address LIKE '%@%edu'
  AND ca.ca_street_type IN ('Pkwy', 'Lane')
  AND ca.ca_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_ship_customer_sk = c.c_customer_sk
          AND ws2.ws_ext_discount_amt > 0
          AND ws2.ws_sold_date_sk > 2450050
    )
ORDER BY ws_agg.total_sales DESC
LIMIT 100
