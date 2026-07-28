WITH expensive_items AS (
    SELECT i_item_sk,
           i_category,
           i_current_price
    FROM   item
    WHERE  i_current_price > 150.00
)
SELECT
    src,
    CASE WHEN i_category IS NULL THEN 'All Categories' ELSE i_category END AS category,
    SUM(amount)                                 AS total_amount,
    AVG(price)                                  AS avg_price,
    (SELECT AVG(i_current_price) FROM item)    AS overall_avg_price
FROM (
    SELECT
        'Return' AS src,
        i.i_category,
        cr.cr_return_amount   AS amount,
        i.i_current_price     AS price
    FROM   catalog_returns cr
    JOIN   item i ON cr.cr_item_sk = i.i_item_sk
    JOIN   reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN   catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE  r.r_reason_desc LIKE '%size%'
      AND  cp.cp_type = 'monthly'
      AND  cr.cr_return_amount > 50

    UNION ALL

    SELECT
        'Sale' AS src,
        i.i_category,
        ws.ws_ext_sales_price AS amount,
        i.i_current_price     AS price
    FROM   web_sales ws
    JOIN   expensive_items ei ON ws.ws_item_sk = ei.i_item_sk
    JOIN   item i ON ws.ws_item_sk = i.i_item_sk
    JOIN   ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE  sm.sm_type = 'AIR'
      AND  ws.ws_ext_sales_price > 200
) u
GROUP BY GROUPING SETS (
    (src, i_category),
    (src),
    ()
)
ORDER BY src, category
LIMIT 100
