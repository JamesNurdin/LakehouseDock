WITH returns_by_reason AS (
    SELECT
        cp.cp_department AS department,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE WHEN SUM(cr.cr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Did not get it on time'
      AND hd.hd_buy_potential = '1001-5000'
    GROUP BY cp.cp_department

    UNION ALL

    SELECT
        cp.cp_department AS department,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE WHEN SUM(cr.cr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Parts missing'
      AND hd.hd_buy_potential = '0-500'
    GROUP BY cp.cp_department
)
SELECT
    department,
    total_return_amount,
    loss_category,
    return_cnt
FROM returns_by_reason
ORDER BY department ASC, total_return_amount DESC
LIMIT 100
