WITH filtered_sales AS (
   SELECT
       ws_bill_customer_sk,
       ws_ship_hdemo_sk,
       ws_ext_ship_cost,
       ws_ext_list_price,
       ws_net_profit,
       ws_quantity
   FROM web_sales
   WHERE ws_ext_ship_cost BETWEEN 30 AND 500
     AND ws_ship_hdemo_sk IN (6132, 3907, 5528)
     AND ws_ext_list_price > 1000
     AND ws_quantity >= 2
     AND ws_ext_list_price < 20000
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_day,
    SUM(fs.ws_net_profit) AS total_profit,
    AVG(fs.ws_ext_ship_cost) AS avg_ship_cost,
    COUNT(*) AS sales_count,
    MIN(fs.ws_ext_list_price) AS min_price,
    MAX(fs.ws_ext_list_price) AS max_price,
    CASE
        WHEN SUM(fs.ws_quantity) > 100 THEN 'High Volume'
        ELSE 'Normal'
    END AS volume_category,
    (
        SELECT SUM(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
    ) AS total_paid_by_customer
FROM customer c
JOIN filtered_sales fs
  ON fs.ws_bill_customer_sk = c.c_customer_sk
WHERE c.c_birth_day IN (7, 19, 30)
  AND c.c_current_addr_sk > 500000
  AND c.c_first_shipto_date_sk BETWEEN 2449000 AND 2452000
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_customer_sk NOT IN (
        SELECT ws_bill_customer_sk
        FROM web_sales
        WHERE ws_ext_ship_cost > 400
    )
  AND EXISTS (
        SELECT 1
        FROM web_sales ws3
        WHERE ws3.ws_bill_customer_sk = c.c_customer_sk
          AND ws3.ws_ext_ship_cost < 50
    )
GROUP BY
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_day
ORDER BY total_profit DESC
LIMIT 100
