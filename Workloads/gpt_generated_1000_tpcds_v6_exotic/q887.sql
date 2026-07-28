WITH inv_item_agg AS (
    SELECT
        i.i_brand_id,
        i.i_category,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        AVG(i.i_current_price) AS avg_price
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE
        inv.inv_date_sk BETWEEN 2450800 AND 2451100
        AND inv.inv_quantity_on_hand > 100
        AND i.i_manufact_id IN (212, 364, 479)
        AND i.i_brand_id <> 6008007
        AND i.i_container <> 'Unknown'
        AND i.i_color = 'Red'
    GROUP BY ROLLUP (i.i_brand_id, i.i_category, inv.inv_warehouse_sk)
)
SELECT
    brand_id,
    SUM(total_qty) AS brand_total_qty,
    AVG(avg_price) AS brand_avg_price
FROM (
    SELECT
        i_brand_id AS brand_id,
        i_category,
        inv_warehouse_sk,
        total_qty,
        avg_price
    FROM inv_item_agg
) agg
WHERE total_qty > 0
GROUP BY brand_id
HAVING SUM(total_qty) > 10000
ORDER BY brand_total_qty DESC
LIMIT 100
