WITH item_inventory AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_color,
        i.i_category,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_color IN ('red', 'lime', 'tan')
    GROUP BY i.i_item_sk, i.i_brand, i.i_color, i.i_category
)
SELECT DISTINCT
    brand,
    color,
    category,
    return_type,
    total_return_amount,
    total_qty_on_hand
FROM (
    SELECT
        ii.i_brand AS brand,
        ii.i_color AS color,
        ii.i_category AS category,
        'store' AS return_type,
        SUM(sr.sr_return_amt) AS total_return_amount,
        ii.total_qty_on_hand
    FROM store_returns sr
    JOIN item_inventory ii ON ii.i_item_sk = sr.sr_item_sk
    WHERE sr.sr_return_quantity > 1
    GROUP BY ii.i_brand, ii.i_color, ii.i_category, ii.total_qty_on_hand

    UNION ALL

    SELECT
        ii.i_brand AS brand,
        ii.i_color AS color,
        ii.i_category AS category,
        'web' AS return_type,
        SUM(wr.wr_return_amt) AS total_return_amount,
        ii.total_qty_on_hand
    FROM web_returns wr
    JOIN item_inventory ii ON ii.i_item_sk = wr.wr_item_sk
    WHERE wr.wr_return_quantity > 1
    GROUP BY ii.i_brand, ii.i_color, ii.i_category, ii.total_qty_on_hand
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
