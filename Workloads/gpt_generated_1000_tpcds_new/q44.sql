WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_item_desc,
        CONCAT(i.i_brand, '-', i.i_category) AS brand_category,
        REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})', 1) AS three_digit_code
    FROM tpcds.item i
    WHERE REGEXP_LIKE(i.i_item_desc, '\\d{3}')
      AND i.i_brand LIKE 'B%'
),
express_ship_modes AS (
    SELECT sm_ship_mode_sk
    FROM tpcds.ship_mode
    WHERE sm_type = 'EXPRESS'
),
intersect_item_keys AS (
    SELECT f.i_item_sk FROM filtered_items f
    INTERSECT
    SELECT ws.ws_item_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM express_ship_modes)
),
item_aggregates AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM tpcds.web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT
    f.i_item_id,
    f.brand_category,
    f.three_digit_code,
    a.total_quantity,
    a.total_profit,
    w.w_warehouse_name,
    sm.sm_type,
    (SELECT MAX(ws2.ws_sold_date_sk) FROM tpcds.web_sales ws2) AS max_sold_date_sk
FROM filtered_items f
JOIN intersect_item_keys ik ON f.i_item_sk = ik.i_item_sk
JOIN item_aggregates a ON f.i_item_sk = a.ws_item_sk
JOIN tpcds.web_sales ws ON ws.ws_item_sk = f.i_item_sk
JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE w.w_city LIKE 'A%'
  AND sm.sm_type LIKE 'EXPRESS%'
ORDER BY a.total_profit DESC
LIMIT 100
