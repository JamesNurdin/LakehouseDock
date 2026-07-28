WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_wholesale_cost,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_class,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_sk,
        w.w_warehouse_name
    FROM catalog_sales cs
    INNER JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_category = 'pants'
      AND i.i_brand = 'ableanti'
      AND cs.cs_wholesale_cost > 30
      AND cr.cr_return_amount > 10
)
SELECT
    sr.i_item_id,
    sr.i_category,
    sr.i_brand,
    sr.w_warehouse_name,
    sr.ship_mode_type,
    SUM(sr.cr_return_amount) AS total_return_amount,
    SUM(sr.cr_return_quantity) AS total_return_qty,
    CASE WHEN SUM(sr.cr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category,
    (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = sr.w_warehouse_sk
    ) AS avg_warehouse_net_loss,
    RANK() OVER (PARTITION BY sr.i_category ORDER BY SUM(sr.cr_return_amount) DESC) AS category_rank
FROM sales_returns sr
GROUP BY
    sr.i_item_id,
    sr.i_category,
    sr.i_brand,
    sr.w_warehouse_name,
    sr.ship_mode_type,
    sr.w_warehouse_sk
ORDER BY category_rank, total_return_amount DESC
LIMIT 100
