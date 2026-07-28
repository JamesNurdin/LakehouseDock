WITH returns AS (
    SELECT i.i_item_id AS item_id,
           cr.cr_return_amt_inc_tax AS amount,
           cr.cr_return_quantity AS qty,
           'return' AS activity
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_class_id = 5
      AND sm.sm_type = 'AIR'
      AND cr.cr_return_amt_inc_tax > 30
),
sales AS (
    SELECT i.i_item_id AS item_id,
           ss.ss_ext_sales_price AS amount,
           ss.ss_quantity AS qty,
           'sale' AS activity
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_class_id = 5
      AND ss.ss_ext_sales_price > 100
)
SELECT item_id,
       SUM(CASE WHEN activity = 'sale' THEN amount ELSE -amount END) AS net_amount,
       SUM(CASE WHEN activity = 'sale' THEN qty    ELSE -qty    END) AS net_quantity
FROM (
    SELECT * FROM returns
    UNION ALL
    SELECT * FROM sales
) AS combined
GROUP BY item_id
ORDER BY net_amount DESC
LIMIT 10
