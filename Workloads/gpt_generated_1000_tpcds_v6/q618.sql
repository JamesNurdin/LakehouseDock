WITH filtered_sales AS (
    SELECT ws_sold_time_sk,
           ws_ship_mode_sk,
           ws_bill_addr_sk,
           ws_ext_sales_price,
           ws_sales_price,
           ws_quantity,
           ws_sold_date_sk,
           ws_order_number
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
      AND ws_quantity >= 2
)
SELECT
    sm.sm_type,
    ca.ca_state,
    td.t_hour,
    COUNT(*) AS order_count,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(ws.ws_ext_sales_price) AS min_sales,
    MAX(ws.ws_ext_sales_price) AS max_sales
FROM filtered_sales ws
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
  AND ca.ca_suite_number = 'Suite 200'
  AND ca.ca_state = 'CA'
  AND td.t_hour BETWEEN 9 AND 17
  AND td.t_am_pm = 'PM'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_addr_sk = ws.ws_bill_addr_sk
          AND ws2.ws_ext_sales_price > 2000
        LIMIT 1
    )
GROUP BY sm.sm_type, ca.ca_state, td.t_hour
HAVING SUM(ws.ws_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
