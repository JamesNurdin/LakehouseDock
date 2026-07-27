WITH recent_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2001
)

SELECT
    d.d_year,
    'Catalog' AS channel,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(cr.cr_net_loss) > (
            SELECT AVG(cr2.cr_net_loss)
            FROM catalog_returns cr2
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category
FROM catalog_returns cr
JOIN recent_dates d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
GROUP BY d.d_year

UNION ALL

SELECT
    d.d_year,
    'Store' AS channel,
    SUM(sr.sr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(sr.sr_net_loss) > (
            SELECT AVG(sr2.sr_net_loss)
            FROM store_returns sr2
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category
FROM store_returns sr
JOIN recent_dates d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
GROUP BY d.d_year
ORDER BY total_net_loss DESC
LIMIT 100
