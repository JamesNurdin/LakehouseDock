WITH returns_set AS (
    SELECT
        i.i_item_id AS item_id,
        w.w_warehouse_name AS warehouse_name,
        d.d_year AS year,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Customer not satisfied'
      AND d.d_year BETWEEN 2000 AND 2002
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
            AND inv.inv_quantity_on_hand > 0
      )
),
promo_set AS (
    SELECT
        i.i_item_id AS item_id,
        w.w_warehouse_name AS warehouse_name,
        d.d_year AS year,
        CASE WHEN p.p_cost > 500 THEN 'Expensive' ELSE 'Cheap' END AS category
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT *
FROM returns_set
EXCEPT
SELECT *
FROM promo_set
ORDER BY item_id, warehouse_name, year
LIMIT 100
