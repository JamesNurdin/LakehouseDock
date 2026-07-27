WITH order_pages AS (
    SELECT DISTINCT wp_web_page_sk
    FROM web_page
    WHERE wp_type = 'order'
),
filtered_sales AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_net_profit > 0
      AND ws.ws_net_paid_inc_ship_tax > 500
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca_bill.ca_state,
    wp.wp_type,
    SUM(fs.ws_net_paid_inc_ship_tax) AS total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY ca_bill.ca_state ORDER BY SUM(fs.ws_net_paid_inc_ship_tax) DESC) AS state_rank
FROM filtered_sales fs
JOIN order_pages op
    ON fs.ws_web_page_sk = op.wp_web_page_sk
JOIN web_page wp
    ON fs.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c
    ON fs.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca_bill
    ON fs.ws_bill_addr_sk = ca_bill.ca_address_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND ca_bill.ca_street_type = 'Ave'
  AND EXISTS (
        SELECT 1
        FROM customer_address ca_ship
        WHERE ca_ship.ca_address_sk = fs.ws_ship_addr_sk
          AND ca_ship.ca_state = 'CA'
    )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca_bill.ca_state,
    wp.wp_type
HAVING SUM(fs.ws_net_paid_inc_ship_tax) > 1000
ORDER BY total_net_paid DESC
LIMIT 10
