SELECT
    sm.sm_ship_mode_id,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cr.cr_refunded_cash) AS total_refunds,
    ws_lateral.ws_net_paid_inc_tax AS ws_one_payment
FROM catalog_sales cs
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN (
    SELECT ws_ship_mode_sk, ws_net_paid_inc_tax
    FROM (
        SELECT ws_ship_mode_sk,
               ws_net_paid_inc_tax,
               row_number() OVER (PARTITION BY ws_ship_mode_sk ORDER BY ws_net_paid_inc_tax) AS rn
        FROM web_sales
        WHERE ws_sold_date_sk = 2451258
    ) sub
    WHERE rn = 1
) ws_lateral
    ON ws_lateral.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_sold_date_sk = 2450852
GROUP BY sm.sm_ship_mode_id, ws_lateral.ws_net_paid_inc_tax
HAVING SUM(cs.cs_ext_sales_price) > 551.00 AND SUM(cr.cr_refunded_cash) < 279.10
