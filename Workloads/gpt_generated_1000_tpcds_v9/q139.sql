WITH cr_sample AS (
    SELECT *
    FROM catalog_returns TABLESAMPLE BERNOULLI (5)
),
wr_sample AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (5)
)
SELECT
    r.r_reason_desc,
    cp.cp_type,
    wp.wp_type,
    SUM(cr.cr_return_amount)                     AS total_catalog_return_amount,
    SUM(wr.wr_return_amt)                        AS total_web_return_amount,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)    AS total_net_loss,
    CASE
        WHEN SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 5000 THEN 'High'
        WHEN SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 1000 THEN 'Medium'
        ELSE 'Low'
    END                                          AS loss_severity,
    SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_amount ELSE 0 END) AS high_qty_return_amount,
    COUNT(*)                                     AS total_returns
FROM cr_sample cr
JOIN catalog_page cp   ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r          ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr   ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp      ON wr.wr_web_page_sk = wp.wp_web_page_sk
-- Additional aliases to increase join count
JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
JOIN catalog_page cp3 ON cr.cr_catalog_page_sk = cp3.cp_catalog_page_sk
JOIN reason r2        ON cr.cr_reason_sk = r2.r_reason_sk
JOIN reason r3        ON wr.wr_reason_sk = r3.r_reason_sk
JOIN web_page wp2    ON wr.wr_web_page_sk = wp2.wp_web_page_sk
GROUP BY GROUPING SETS (
    (r.r_reason_desc, cp.cp_type, wp.wp_type),
    (r.r_reason_desc, cp.cp_type),
    (r.r_reason_desc, wp.wp_type),
    (r.r_reason_desc),
    ()
)
ORDER BY total_net_loss DESC
LIMIT 100
