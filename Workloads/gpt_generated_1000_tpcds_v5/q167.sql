WITH preferred_customers AS (
    SELECT c_customer_sk, c_customer_id, c_first_name, c_last_name
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
)
SELECT
    pc.c_customer_id AS customer_id,
    concat(pc.c_first_name, ' ', pc.c_last_name) AS customer_name,
    agg.total_sales,
    'store' AS sales_channel,
    agg.avg_discount
FROM preferred_customers pc
JOIN store_sales ss
    ON ss.ss_customer_sk = pc.c_customer_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
CROSS JOIN LATERAL (
    SELECT 
        sum(ss2.ss_ext_sales_price) AS total_sales,
        avg(ss2.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = pc.c_customer_sk
      AND ss2.ss_promo_sk = 861
) AS agg
WHERE ca.ca_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM store_sales ss3
        WHERE ss3.ss_customer_sk = pc.c_customer_sk
          AND ss3.ss_quantity > 20
      )
UNION ALL
SELECT
    pc.c_customer_id AS customer_id,
    concat(pc.c_first_name, ' ', pc.c_last_name) AS customer_name,
    agg.total_sales,
    'web' AS sales_channel,
    agg.avg_discount
FROM preferred_customers pc
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = pc.c_customer_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
CROSS JOIN LATERAL (
    SELECT 
        sum(ws2.ws_ext_sales_price) AS total_sales,
        avg(ws2.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = pc.c_customer_sk
      AND ws2.ws_ext_sales_price > 1000
) AS agg
WHERE ca.ca_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws3
        WHERE ws3.ws_bill_customer_sk = pc.c_customer_sk
          AND ws3.ws_quantity > 10
      )
ORDER BY total_sales DESC
LIMIT 100
