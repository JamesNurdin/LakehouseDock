WITH sales_summary AS (
    SELECT
        cs.cs_order_number AS order_number,
        i.i_item_id AS item_id,
        sm.sm_ship_mode_id AS ship_mode_id,
        SUM(cs.cs_ext_sales_price) AS metric,
        'sale' AS trans_type
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ext_list_price > 5000
      AND i.i_manufact_id IN (260, 630)
    GROUP BY cs.cs_order_number, i.i_item_id, sm.sm_ship_mode_id
    HAVING SUM(cs.cs_ext_sales_price) > 10000
),

returns_summary AS (
    SELECT
        cr.cr_order_number AS order_number,
        i.i_item_id AS item_id,
        sm.sm_ship_mode_id AS ship_mode_id,
        SUM(cr.cr_return_amount) AS metric,
        'return' AS trans_type
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 500
      AND i.i_size = 'economy'
    GROUP BY cr.cr_order_number, i.i_item_id, sm.sm_ship_mode_id
    HAVING SUM(cr.cr_return_amount) > 1000
),

combined AS (
    SELECT order_number, item_id, ship_mode_id, metric, trans_type
    FROM sales_summary
    UNION ALL
    SELECT order_number, item_id, ship_mode_id, metric, trans_type
    FROM returns_summary
)

SELECT
    c.order_number,
    c.item_id,
    c.ship_mode_id,
    c.metric,
    c.trans_type
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_order_number = c.order_number
      AND cr.cr_return_amount > 2000
)
ORDER BY c.metric DESC
LIMIT 100
