WITH sales_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE w.w_gmt_offset = -5.00
      AND sm.sm_type = 'AIR'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
),
return_orders AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE w.w_gmt_offset = -5.00
      AND sm.sm_type = 'AIR'
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
),
customer_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
),
low_stock_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN inventory i ON cs.cs_item_sk = i.inv_item_sk AND cs.cs_warehouse_sk = i.inv_warehouse_sk
    WHERE i.inv_quantity_on_hand < 10
),
union_set AS (
    SELECT order_number FROM sales_orders
    UNION
    SELECT order_number FROM return_orders
),
filtered_union AS (
    SELECT order_number
    FROM union_set
    WHERE order_number NOT IN (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        WHERE cs.cs_quantity = 0
    )
),
final_set AS (
    SELECT order_number FROM filtered_union
    INTERSECT
    SELECT order_number FROM customer_orders
    EXCEPT
    SELECT order_number FROM low_stock_orders
)
SELECT fs.order_number,
       (SELECT COUNT(*) FROM catalog_sales) AS total_sales_orders
FROM final_set fs
ORDER BY fs.order_number
LIMIT 100
