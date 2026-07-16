SELECT c.c_customer_id,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       sm.sm_type AS ship_type
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE c.c_birth_year = 1933
  AND sm.sm_carrier = 'UPS                 '
  AND ws.ws_sold_date_sk BETWEEN 2452331 AND 2452504
  AND ws.ws_item_sk IN (SELECT ws2.ws_item_sk FROM web_sales ws2 WHERE ws2.ws_ext_discount_amt > 2422.54)
GROUP BY c.c_customer_id, sm.sm_type
HAVING COUNT(*) > 10
