WITH sales_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        'sales_volume' AS metric,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_count >= 2
    GROUP BY w.w_warehouse_id
),
inventory_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        'inventory_qty' AS metric,
        SUM(i.inv_quantity_on_hand) AS total_amount,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(i.inv_quantity_on_hand) DESC) AS rank
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_county = 'Mobile County'
      AND i.inv_quantity_on_hand > 500
      AND i.inv_date_sk BETWEEN 2450850 AND 2451067
    GROUP BY w.w_warehouse_id
)
SELECT
    warehouse_id,
    metric,
    total_amount,
    rank
FROM sales_agg
UNION ALL
SELECT
    warehouse_id,
    metric,
    total_amount,
    rank
FROM inventory_agg
ORDER BY warehouse_id, metric
