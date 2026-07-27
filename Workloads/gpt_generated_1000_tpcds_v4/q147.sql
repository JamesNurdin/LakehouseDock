WITH catalog_ret AS (
    SELECT
        'Catalog' AS return_source,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
    GROUP BY r.r_reason_desc
),
web_ret AS (
    SELECT
        'Web' AS return_source,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    WHERE wp.wp_type = 'content'
    GROUP BY r.r_reason_desc
)
SELECT
    return_source,
    reason_desc,
    total_return_amount,
    total_return_quantity,
    return_count
FROM (
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
) combined
ORDER BY total_return_amount DESC
LIMIT 100
