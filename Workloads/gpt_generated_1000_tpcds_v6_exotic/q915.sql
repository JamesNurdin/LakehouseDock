WITH sales_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_coupon_amt,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_coupon_amt < 5000
      AND regexp_like(cast(ws.ws_order_number AS varchar), '^1[0-9]{5}$')
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    sm.sm_ship_mode_id,
    sm.sm_type,
    wsf.ws_order_number,
    ws_max.max_sales_price,
    SUM(wsf.ws_net_profit) AS total_profit,
    COUNT(*) AS order_count
FROM sales_filtered wsf
JOIN tpcds.customer c
    ON wsf.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.ship_mode sm
    ON wsf.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_site wsit
    ON wsf.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN tpcds.web_page wp
    ON wsf.ws_web_page_sk = wp.wp_web_page_sk
JOIN LATERAL (
    SELECT MAX(ws2.ws_ext_sales_price) AS max_sales_price
    FROM tpcds.web_sales ws2
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
) ws_max ON TRUE
WHERE regexp_like(wsit.web_city, '^S.*')                     -- city name starts with "S"
  AND wsit.web_suite_number LIKE '%3%'                     -- suite contains a "3"
  AND regexp_like(sm.sm_contract, '^.{5}M8')               -- contract pattern
  AND (wp.wp_url IS NULL OR strpos(wp.wp_url, 'product') > 0)  -- URL contains "product"
  AND NOT EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws_ex
        WHERE ws_ex.ws_bill_customer_sk = c.c_customer_sk
          AND ws_ex.ws_coupon_amt > 6000
    )
GROUP BY
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name),
    sm.sm_ship_mode_id,
    sm.sm_type,
    wsf.ws_order_number,
    ws_max.max_sales_price
ORDER BY total_profit DESC
LIMIT 100
