WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_product_name,
        ws.ws_ext_sales_price,
        ws.ws_ext_ship_cost,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn_item_sales,
        (
            SELECT max(ws_sub.ws_ext_ship_cost)
            FROM web_sales ws_sub
            WHERE ws_sub.ws_item_sk = ws.ws_item_sk
              AND ws_sub.ws_ship_date_sk = ws.ws_ship_date_sk
        ) AS max_ship_cost_for_item_date
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT sm_ship_mode_id, sm_contract
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
          AND sm.sm_contract LIKE 'P%'
    ) sm
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_manager_id IN (26, 34)
      AND ws.ws_ext_ship_cost > 200
      AND ws.ws_ext_sales_price > 1000
)
SELECT
    ws_order_number,
    i_product_name,
    ws_ext_sales_price,
    ws_ext_ship_cost,
    sm_ship_mode_id,
    w_warehouse_name,
    rn_item_sales,
    max_ship_cost_for_item_date
FROM filtered_sales
WHERE rn_item_sales <= 5
UNION
SELECT
    ws.ws_order_number,
    i.i_product_name,
    ws.ws_ext_sales_price,
    ws.ws_ext_ship_cost,
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price ASC) AS rn_item_sales,
    (
        SELECT min(ws_sub.ws_ext_ship_cost)
        FROM web_sales ws_sub
        WHERE ws_sub.ws_item_sk = ws.ws_item_sk
          AND ws_sub.ws_ship_date_sk = ws.ws_ship_date_sk
    ) AS min_ship_cost_for_item_date
FROM web_sales ws
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE i.i_manager_id = 41
  AND sm.sm_contract LIKE '%Bg%'
  AND ws.ws_ext_ship_cost BETWEEN 100 AND 5000
  AND ws.ws_ext_sales_price < 3000
LIMIT 100
