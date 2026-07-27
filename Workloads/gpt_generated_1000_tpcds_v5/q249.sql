WITH combined_returns AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        COUNT(*) AS catalog_return_cnt,
        SUM(cr.cr_return_amt_inc_tax) AS catalog_total_inc_tax,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        0 AS store_return_cnt,
        0 AS store_total_inc_tax,
        0 AS store_net_loss
    FROM tpcds.catalog_returns cr
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_refunded_hdemo_sk > 500
      AND cr.cr_return_quantity > 1
      AND r.r_reason_id LIKE 'AAAAAA%'
    GROUP BY r.r_reason_desc

    UNION ALL

    SELECT
        r.r_reason_desc AS reason_desc,
        0 AS catalog_return_cnt,
        0 AS catalog_total_inc_tax,
        0 AS catalog_net_loss,
        COUNT(*) AS store_return_cnt,
        SUM(sr.sr_return_amt_inc_tax) AS store_total_inc_tax,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM tpcds.store_returns sr
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_quantity > 1
      AND r.r_reason_desc LIKE '%warranty%'
    GROUP BY r.r_reason_desc
)
SELECT
    reason_desc,
    SUM(catalog_return_cnt) AS total_catalog_cnt,
    SUM(store_return_cnt) AS total_store_cnt,
    SUM(catalog_total_inc_tax) + SUM(store_total_inc_tax) AS total_inc_tax,
    SUM(catalog_net_loss) + SUM(store_net_loss) AS total_net_loss
FROM combined_returns
GROUP BY reason_desc
HAVING SUM(catalog_return_cnt + store_return_cnt) > 5
ORDER BY total_inc_tax DESC
LIMIT 100
