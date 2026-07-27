WITH ws_filtered AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_ext_discount_amt,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk
    FROM web_sales ws
    WHERE ws.ws_ext_discount_amt IS NOT NULL
)
SELECT
    w.w_city,
    concat(w.w_city, ' - ', w.w_street_name) AS city_street,
    sum(ws.ws_net_profit) AS total_net_profit,
    count(DISTINCT ws.ws_order_number) AS unique_orders,
    max(ws.ws_ext_discount_amt) AS max_discount,
    (SELECT max(cr.cr_return_amount) FROM catalog_returns cr) AS max_return_amount
FROM ws_filtered ws
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE regexp_like(w.w_street_name, '^[0-9]+')
  AND c.c_email_address LIKE '%@gmail.com'
  AND cd.cd_gender = 'M'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
          AND cr.cr_return_amount > 1000
    )
GROUP BY
    w.w_city,
    concat(w.w_city, ' - ', w.w_street_name)
HAVING sum(ws.ws_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
