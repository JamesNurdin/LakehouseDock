/*
Goal: Identify the top-selling product brands and categories whose item description contains a three‑digit code, using regular‑expression extraction and pattern matching, and report sales performance metrics aggregated by brand, category and extracted code.
*/
WITH items_with_code AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        regexp_extract(i.i_item_desc, '(\\d{3})') AS code3,
        CONCAT(i.i_brand, '-', regexp_extract(i.i_item_desc, '(\\d{3})')) AS brand_code
    FROM item i
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
      AND i.i_item_desc LIKE '%COLOUR%'
    GROUP BY i.i_item_sk, i.i_brand, i.i_category, i.i_item_desc
)
SELECT
    ibc.i_brand,
    ibc.i_category,
    ibc.code3,
    ibc.brand_code,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count
FROM items_with_code ibc
JOIN web_sales ws
    ON ws.ws_item_sk = ibc.i_item_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type LIKE 'EXPRESS%'
GROUP BY
    ibc.i_brand,
    ibc.i_category,
    ibc.code3,
    ibc.brand_code
ORDER BY total_net_paid DESC
LIMIT 100
