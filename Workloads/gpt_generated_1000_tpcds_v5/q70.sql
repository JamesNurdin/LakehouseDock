WITH item_sales AS (
    SELECT
        CONCAT(i.i_category, ':', i.i_item_id) AS name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        REGEXP_EXTRACT(i.i_formulation, '([a-z]+)', 1) AS formulation_alpha
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '\\d{3}')
      AND w.w_warehouse_name LIKE '%childr%'
      AND hd.hd_buy_potential LIKE 'high%'
    GROUP BY i.i_category, i.i_item_id, i.i_formulation
),
warehouse_sales AS (
    SELECT
        w.w_warehouse_name AS name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CAST(NULL AS varchar) AS formulation_alpha
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '\\d{3}')
      AND w.w_warehouse_name LIKE '%childr%'
    GROUP BY w.w_warehouse_name
)
SELECT
    'Item' AS level,
    name,
    total_sales,
    formulation_alpha
FROM item_sales
UNION ALL
SELECT
    'Warehouse' AS level,
    name,
    total_sales,
    formulation_alpha
FROM warehouse_sales
ORDER BY total_sales DESC
LIMIT 100
