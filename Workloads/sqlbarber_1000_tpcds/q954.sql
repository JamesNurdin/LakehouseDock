SELECT
    c.c_customer_id,
    d.d_year,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS order_count,
    max_ws.max_ws_net_paid
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
CROSS JOIN LATERAL (
    SELECT ws2.ws_net_paid AS max_ws_net_paid
    FROM web_sales ws2
    JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
      AND d2.d_year = d.d_year
    ORDER BY ws2.ws_net_paid DESC
    LIMIT 1
) AS max_ws
WHERE d.d_year = 1925
  AND hd.hd_buy_potential = '501-1000       '
GROUP BY c.c_customer_id, d.d_year, max_ws.max_ws_net_paid
HAVING SUM(ws.ws_net_paid) > 1718.40
ORDER BY total_net_paid DESC
LIMIT 100
