WITH returns_with_cc AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cdemo_sk,
        cr.cr_ship_mode_sk,
        cc.cc_name,
        cc.cc_state,
        sm.sm_contract
    FROM catalog_returns cr
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 1000
      AND cr.cr_return_quantity >= 2
      AND cr.cr_refunded_cdemo_sk = 1245326
      AND cr.cr_return_ship_cost BETWEEN 50 AND 150
      AND sm.sm_contract = 'A5BYO1qH8HGTTN'
      AND cc.cc_state = 'CA'
)
SELECT
    ws.ws_ship_mode_sk,
    sm.sm_contract,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(ws.ws_net_profit) AS min_profit,
    MAX(ws.ws_net_profit) AS max_profit
FROM returns_with_cc r
JOIN web_sales ws
    ON ws.ws_ship_mode_sk = r.cr_ship_mode_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_ext_list_price > 500
  AND ws.ws_ship_customer_sk = 10121251
  AND ws.ws_sales_price BETWEEN 10 AND 50
  AND ws.ws_quantity >= 1
  AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
  AND sm.sm_contract = 'A5BYO1qH8HGTTN'
GROUP BY ws.ws_ship_mode_sk, sm.sm_contract
ORDER BY total_sales DESC
LIMIT 100
