WITH page_returns AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_number,
        d.d_quarter_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        sm.sm_code = 'AIR'
        AND w.w_gmt_offset BETWEEN -5 AND 5
        AND cp.cp_catalog_number IN (5, 7)
        AND d.d_quarter_name IN ('1902Q3', '1903Q2')
        AND cr.cr_return_amount > 100.00
        AND d.d_year = 1999
        AND EXISTS (
            SELECT 1
            FROM web_site ws
            WHERE ws.web_open_date_sk = d.d_date_sk
              AND ws.web_country = 'USA'
        )
        AND cp.cp_catalog_page_id IN (
            SELECT wp.wp_url
            FROM web_page wp
            WHERE wp.wp_type = 'article'
        )
    GROUP BY
        cp.cp_catalog_page_sk,
        cp.cp_catalog_number,
        d.d_quarter_name
)
SELECT
    pr.d_quarter_name AS quarter,
    AVG(pr.total_return_amount) AS avg_return_amount,
    SUM(pr.total_return_qty) AS total_return_quantity,
    COUNT(DISTINCT pr.cp_catalog_page_sk) AS distinct_pages
FROM page_returns pr
GROUP BY pr.d_quarter_name
HAVING AVG(pr.total_return_amount) > 200.00
ORDER BY pr.d_quarter_name
