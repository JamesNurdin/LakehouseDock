WITH sales_detail AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_net_paid,
        ws.ws_quantity
    FROM web_sales ws
    WHERE ws.ws_net_paid > 0
)
SELECT
    i.i_brand,
    sm.sm_carrier,
    MAX(substring(i.i_item_id, 1, 5)) AS item_prefix,
    SUM(sd.ws_net_paid) AS total_net_paid,
    SUM(sd.ws_quantity) AS total_quantity,
    COUNT(*) AS transaction_cnt
FROM sales_detail sd
JOIN item i ON sd.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = sd.ws_item_sk
)
  AND regexp_like(i.i_item_desc, '^.*[A-Z]{2,}.*$')
  AND i.i_color LIKE 'R%'
GROUP BY GROUPING SETS (
    (i.i_brand, sm.sm_carrier),
    (i.i_brand),
    (sm.sm_carrier),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
