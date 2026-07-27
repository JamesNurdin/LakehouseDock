WITH base AS (
    SELECT
        i.i_brand,
        i.i_brand_id,
        w.w_warehouse_name,
        w.w_state,
        inv.inv_quantity_on_hand,
        ws.ws_ext_sales_price,
        ws.ws_ext_ship_cost,
        ws.ws_quantity,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_brand_id IN (5002002, 3001002)
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 100
      AND ws.ws_ext_ship_cost > 200
      AND ws.ws_quantity > 5
)
SELECT
    COALESCE(brand, 'ALL_BRANDS') AS brand,
    COALESCE(warehouse, 'ALL_WAREHOUSES') AS warehouse,
    total_sales,
    total_units,
    sales_category,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        i_brand AS brand,
        w_warehouse_name AS warehouse,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_units,
        CASE
            WHEN SUM(ws_ext_sales_price) > 100000 THEN 'HIGH'
            WHEN SUM(ws_ext_sales_price) > 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS sales_category
    FROM base
    GROUP BY ROLLUP (i_brand, w_warehouse_name)
) agg
WHERE total_sales IS NOT NULL
ORDER BY total_sales DESC, brand
LIMIT 100
