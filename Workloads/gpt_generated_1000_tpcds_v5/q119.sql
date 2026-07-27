SELECT
    c.c_birth_country,
    CASE WHEN cr.cr_return_amount > 100 THEN 'high' ELSE 'low' END AS return_amount_category,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
    MIN(ws.ws_net_paid) AS min_net_paid,
    MAX(ws.ws_net_paid) AS max_net_paid
FROM catalog_returns cr
JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
          AND wp.wp_type = 'product'
      )
  AND c.c_birth_country IN ('UKRAINE', 'NIUE')
  AND c.c_current_hdemo_sk BETWEEN 500 AND 3000
  AND ws.ws_ext_ship_cost > 100.00
  AND cr.cr_return_amount > 50.00
GROUP BY
    c.c_birth_country,
    CASE WHEN cr.cr_return_amount > 100 THEN 'high' ELSE 'low' END
ORDER BY
    total_return_amount DESC,
    c.c_birth_country
