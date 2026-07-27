WITH q1 AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_amount_category,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY inv.inv_quantity_on_hand DESC) AS brand_qty_rank
    FROM
        inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    WHERE
        i.i_manufact_id IN (260, 167, 460)
        AND i.i_manager_id = 41
        AND i.i_rec_end_date = DATE '2000-10-26'
        AND inv.inv_date_sk BETWEEN 2450941 AND 2451067
        AND inv.inv_warehouse_sk IN (15, 19)
        AND wr.wr_return_tax > 10.00
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        i.i_brand
),
q2 AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        0 AS total_return_qty,
        'NO_RETURNS' AS return_amount_category,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY inv.inv_quantity_on_hand DESC) AS brand_qty_rank
    FROM
        inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE
        i.i_manufact_id = 479
        AND i.i_manager_id = 98
        AND i.i_rec_end_date = DATE '1999-10-27'
        AND inv.inv_date_sk = 2450934
        AND inv.inv_warehouse_sk = 7
        AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_item_sk = i.i_item_sk
              AND wr.wr_return_tax > 20.00
        )
)
SELECT
    i_item_id,
    i_product_name,
    inv_warehouse_sk,
    inv_quantity_on_hand,
    total_return_qty,
    return_amount_category,
    brand_qty_rank
FROM q1
UNION ALL
SELECT
    i_item_id,
    i_product_name,
    inv_warehouse_sk,
    inv_quantity_on_hand,
    total_return_qty,
    return_amount_category,
    brand_qty_rank
FROM q2
ORDER BY return_amount_category DESC, brand_qty_rank, i_item_id
LIMIT 100
