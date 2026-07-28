WITH filtered AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        i.inv_item_sk,
        d.d_date,
        w.w_warehouse_name,
        w.w_city,
        w.w_street_type,
        w.w_suite_number,
        w.w_zip,
        regexp_extract(w.w_suite_number, '(\\d+)', 1) AS suite_num
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_current_year = 'Y'
      AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND regexp_like(w.w_street_type, '^R.*')
      AND w.w_zip LIKE '78%'
      AND CAST(regexp_extract(w.w_suite_number, '(\\d+)', 1) AS integer) > 100
)
SELECT
    w_warehouse_name,
    w_city,
    CONCAT(w_street_type, ' ', w_zip) AS street_zip,
    suite_num,
    SUM(inv_quantity_on_hand) AS total_qty_on_hand,
    COUNT(DISTINCT inv_item_sk) AS distinct_items
FROM filtered
GROUP BY
    w_warehouse_name,
    w_city,
    CONCAT(w_street_type, ' ', w_zip),
    suite_num
ORDER BY total_qty_on_hand DESC
LIMIT 10
