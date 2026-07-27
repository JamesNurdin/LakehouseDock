WITH item_filtered AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        regexp_extract(i.i_item_id, '\\d+') AS extracted_number,
        i.i_current_price
    FROM tpcds.item i
    WHERE regexp_like(i.i_item_desc, '(?i)large')
      AND i.i_item_desc LIKE '%size%'
)
SELECT
    it.i_item_id,
    it.i_brand,
    it.extracted_number,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
    COUNT(DISTINCT w.w_warehouse_id) AS warehouse_count
FROM item_filtered it
JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = it.i_item_sk
JOIN tpcds.inventory inv
    ON inv.inv_item_sk = it.i_item_sk
JOIN tpcds.warehouse w
    ON w.w_warehouse_sk = inv.inv_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM tpcds.warehouse w2
    WHERE w2.w_warehouse_sk = inv.inv_warehouse_sk
      AND w2.w_state = 'CA'
)
GROUP BY
    it.i_item_id,
    it.i_brand,
    it.extracted_number
ORDER BY total_return_amount DESC
LIMIT 100
