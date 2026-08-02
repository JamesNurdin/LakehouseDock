WITH sampled_inventory AS (
    SELECT inv.inv_date_sk,
           inv.inv_item_sk,
           inv.inv_warehouse_sk,
           inv.inv_quantity_on_hand
    FROM inventory AS inv
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_state,
    cr.cr_order_number,
    cr.cr_return_quantity,
    cr.cr_return_amt_inc_tax,
    cr.cr_fee,
    inv.inv_quantity_on_hand,
    CASE 
        WHEN cr.cr_return_amt_inc_tax > 3000 THEN 'High'
        WHEN cr.cr_return_amt_inc_tax > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY cr.cr_return_amt_inc_tax DESC) AS rn_state,
    AVG(cr.cr_return_amt_inc_tax) OVER (PARTITION BY w.w_state) AS avg_return_amt_state,
    (SELECT COUNT(*)
     FROM catalog_returns cr2
     WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
       AND cr2.cr_return_quantity > 0) AS total_returns_in_warehouse
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN sampled_inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    cr.cr_return_quantity > 0
    AND cr.cr_return_amt_inc_tax > 0
    AND cr.cr_fee >= 0
    AND inv.inv_quantity_on_hand > 100
    AND inv.inv_item_sk BETWEEN 101410 AND 101443
    AND w.w_state IN ('CA', 'TX', 'NY')
    AND w.w_gmt_offset BETWEEN -5 AND 5
ORDER BY w.w_state, rn_state
LIMIT 100
