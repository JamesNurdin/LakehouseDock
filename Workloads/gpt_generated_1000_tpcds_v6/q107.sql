WITH warehouse_sales AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_county,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax,
        SUM(i.inv_quantity_on_hand) AS total_on_hand,
        CASE
            WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'HIGH'
            ELSE 'LOW'
        END AS sales_level
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_county IN ('Bronx County', 'Richland County')
      AND w.w_warehouse_sq_ft > 500000
      AND cs.cs_list_price BETWEEN 50 AND 200
      AND cs.cs_net_paid_inc_ship_tax > 1000
      AND i.inv_quantity_on_hand >= 0
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_county
)
SELECT
    ws.w_warehouse_name,
    ws.w_county,
    ws.total_sales,
    ws.total_quantity,
    ws.avg_net_paid_inc_ship_tax,
    ws.total_on_hand,
    ws.sales_level,
    (
        SELECT MAX(cs.cs_list_price)
        FROM catalog_sales cs
        WHERE cs.cs_warehouse_sk = ws.w_warehouse_sk
    ) AS max_list_price
FROM warehouse_sales ws
WHERE ws.total_sales > (
    SELECT AVG(total_sales) FROM warehouse_sales
)
ORDER BY ws.total_sales DESC
LIMIT 20
