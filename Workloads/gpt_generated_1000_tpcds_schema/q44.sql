SELECT
    d_cr.d_year AS year,
    CASE WHEN cr.cr_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss
FROM catalog_returns cr
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN date_dim d_cr2 ON cr.cr_returned_date_sk = d_cr2.d_date_sk
CROSS JOIN store_returns sr
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN date_dim d_sr2 ON sr.sr_returned_date_sk = d_sr2.d_date_sk
CROSS JOIN web_returns wr
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN date_dim d_wr2 ON wr.wr_returned_date_sk = d_wr2.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN date_dim d_access2 ON wp.wp_access_date_sk = d_access2.d_date_sk
WHERE EXISTS (
    SELECT 1 FROM catalog_returns cr2
    WHERE cr2.cr_reason_sk = cr.cr_reason_sk
      AND cr2.cr_returned_date_sk = cr.cr_returned_date_sk
      AND cr2.cr_order_number <> cr.cr_order_number
)
GROUP BY d_cr.d_year,
    CASE WHEN cr.cr_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END
ORDER BY total_net_loss DESC
LIMIT 100
