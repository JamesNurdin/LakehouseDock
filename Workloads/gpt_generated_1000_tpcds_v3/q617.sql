WITH item_return_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_wholesale_cost,
        i.i_size,
        i.i_manager_id,
        cr.cr_catalog_page_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE
        i.i_wholesale_cost > 5
        AND i.i_wholesale_cost < 50
        AND i.i_size IN ('medium', 'large')
        AND i.i_manager_id IN (41, 44, 19)
        AND cr.cr_return_amount > 100
        AND cr.cr_return_quantity >= 1
        AND cr.cr_return_amt_inc_tax > 0
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_wholesale_cost,
        i.i_size,
        i.i_manager_id,
        cr.cr_catalog_page_sk
), item_with_dept AS (
    SELECT
        ira.*,
        (SELECT cp.cp_department
         FROM catalog_page cp
         WHERE cp.cp_catalog_page_sk = ira.cr_catalog_page_sk) AS department
    FROM item_return_agg ira
    WHERE EXISTS (
        SELECT 1
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = ira.cr_catalog_page_sk
          AND cp.cp_department = 'Electronics'
          AND cp.cp_type = 'Standard'
    )
)
SELECT
    CASE
        WHEN iwd.i_wholesale_cost >= 20 THEN 'expensive'
        ELSE 'affordable'
    END AS price_category,
    iwd.department,
    COUNT(DISTINCT iwd.i_item_sk) AS distinct_items,
    SUM(iwd.total_return_qty) AS sum_return_qty,
    AVG(iwd.total_return_amount) AS avg_return_amount,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    CASE
        WHEN AVG(iwd.total_return_amount) > 1000 THEN 'high'
        ELSE 'moderate'
    END AS return_level
FROM item_with_dept iwd
JOIN inventory inv
    ON inv.inv_item_sk = iwd.i_item_sk
WHERE inv.inv_quantity_on_hand > 10
GROUP BY
    CASE
        WHEN iwd.i_wholesale_cost >= 20 THEN 'expensive'
        ELSE 'affordable'
    END,
    iwd.department
HAVING
    COUNT(DISTINCT iwd.i_item_sk) >= 5
    AND SUM(iwd.total_return_qty) > 20
    AND AVG(inv.inv_quantity_on_hand) > 15
ORDER BY
    avg_return_amount DESC
LIMIT 100
