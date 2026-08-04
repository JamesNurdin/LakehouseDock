WITH inv_data AS (
    SELECT
        'inventory' AS src,
        inv.inv_warehouse_sk AS key_id,
        d.d_date AS date_val,
        inv.inv_quantity_on_hand AS quantity,
        ARRAY[inv.inv_quantity_on_hand, inv.inv_item_sk] AS vals
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
      AND inv.inv_quantity_on_hand > 800
),
call_data AS (
    SELECT
        'call_center' AS src,
        cc.cc_call_center_sk AS key_id,
        d.d_date AS date_val,
        cc.cc_employees AS quantity,
        ARRAY[cc.cc_employees, cc.cc_sq_ft] AS vals
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq = 10
      AND cc.cc_employees > 0
)
SELECT
    src,
    key_id,
    date_val,
    quantity,
    val
FROM (
    SELECT src, key_id, date_val, quantity, vals FROM inv_data
    UNION ALL
    SELECT src, key_id, date_val, quantity, vals FROM call_data
) AS combined
CROSS JOIN UNNEST(vals) AS t(val)
ORDER BY src, date_val DESC
LIMIT 100
