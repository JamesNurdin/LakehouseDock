WITH inv_item_summary AS (
    SELECT
        i.i_category AS category,
        i.i_brand AS brand,
        cp.cp_catalog_number AS catalog_number,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        AVG(i.i_current_price) AS avg_price
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_inv.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
      AND d_inv.d_current_year = 'Y'
      AND inv.inv_quantity_on_hand > 0
      AND i.i_current_price BETWEEN 10 AND 1000
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'A'
    GROUP BY i.i_category, i.i_brand, cp.cp_catalog_number
)
SELECT
    category,
    brand,
    SUM(total_qty) AS category_total_qty,
    AVG(avg_price) AS category_avg_price
FROM inv_item_summary
GROUP BY category, brand
HAVING SUM(total_qty) > 500
ORDER BY category_total_qty DESC
LIMIT 100
