WITH high_profit_items AS (
    SELECT i.i_item_id
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_profit > 1000
      AND ss.ss_sold_date_sk BETWEEN 2451019 AND 2451132
    GROUP BY i.i_item_id
),
high_loss_returns AS (
    SELECT i.i_item_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_net_loss > 500
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_item_id
),
expensive_items AS (
    SELECT i.i_item_id
    FROM item i
    WHERE i.i_current_price > 200
),
intersect_items AS (
    SELECT i_item_id
    FROM high_profit_items
    INTERSECT
    SELECT i_item_id FROM high_loss_returns
),
combined_items AS (
    SELECT i_item_id FROM intersect_items
    UNION
    SELECT i_item_id FROM expensive_items
)
SELECT i.i_item_id,
       i.i_item_desc,
       i.i_current_price,
       CASE
           WHEN ii.i_item_id IS NOT NULL THEN 'INTERSECTED'
           ELSE 'EXPENSIVE_ONLY'
       END AS source_type
FROM combined_items ci
JOIN item i ON ci.i_item_id = i.i_item_id
LEFT JOIN intersect_items ii ON ci.i_item_id = ii.i_item_id
ORDER BY i.i_item_id
