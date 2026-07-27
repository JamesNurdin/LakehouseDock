WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)

SELECT
    'Catalog' AS return_channel,
    COALESCE(w.w_warehouse_name, 'Unknown') AS warehouse_name,
    r.r_reason_desc AS reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Normal' END AS loss_category,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = cr.cr_reason_sk
          AND cr2.cr_returned_date_sk IN (SELECT d_date_sk FROM recent_dates)
    ) AS avg_return_amount_by_reason
FROM catalog_returns cr
JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
GROUP BY
    w.w_warehouse_name,
    r.r_reason_desc,
    cr.cr_reason_sk

UNION ALL

SELECT
    'Web' AS return_channel,
    'Web' AS warehouse_name,
    r.r_reason_desc AS reason_desc,
    SUM(wr.wr_return_amt) AS total_return_amount,
    CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Normal' END AS loss_category,
    (
        SELECT AVG(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_reason_sk = wr.wr_reason_sk
          AND wr2.wr_returned_date_sk IN (SELECT d_date_sk FROM recent_dates)
    ) AS avg_return_amount_by_reason
FROM web_returns wr
JOIN recent_dates rd ON wr.wr_returned_date_sk = rd.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
GROUP BY
    r.r_reason_desc,
    wr.wr_reason_sk

ORDER BY total_return_amount DESC
LIMIT 100
