WITH returns_agg AS (
    SELECT
        c.c_customer_id,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(wr.wr_return_amt) AS web_return_amount,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_catalog_pages
    FROM catalog_page cp
    JOIN catalog_returns cr ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
    JOIN customer c ON c.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
    WHERE
        hd.hd_buy_potential IN ('0-500', '1001-5000')
        AND hd.hd_vehicle_count > 0
        AND sm.sm_type = 'AIR'
        AND cp.cp_department = 'Electronics'
        AND cr.cr_return_amount > 100
    GROUP BY
        c.c_customer_id,
        r.r_reason_desc
)
SELECT
    r_reason_desc,
    AVG(catalog_return_amount) AS avg_catalog_return,
    AVG(store_return_amount) AS avg_store_return,
    AVG(web_return_amount) AS avg_web_return,
    AVG(distinct_catalog_pages) AS avg_distinct_pages
FROM returns_agg
GROUP BY r_reason_desc
HAVING AVG(catalog_return_amount) > 200
ORDER BY avg_catalog_return DESC
LIMIT 100
