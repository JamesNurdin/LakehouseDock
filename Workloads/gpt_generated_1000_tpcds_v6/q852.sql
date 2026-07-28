WITH max_catalog_price AS (
    SELECT max(cs_ext_sales_price) AS max_price
    FROM catalog_sales
)
SELECT
    c.c_customer_id,
    'store' AS sales_channel,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    (SELECT max_price FROM max_catalog_price) AS max_catalog_price
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
)
GROUP BY c.c_customer_id

UNION ALL

SELECT
    c.c_customer_id,
    'web' AS sales_channel,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    (SELECT max_price FROM max_catalog_price) AS max_catalog_price
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier = 'DHL'
GROUP BY c.c_customer_id

ORDER BY total_profit DESC, total_sales DESC
LIMIT 100
