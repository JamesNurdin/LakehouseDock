WITH returns_dt AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d.d_date,
        d.d_holiday
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
)
SELECT
    'Holiday' AS period_type,
    r.d_date,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM returns_dt r
JOIN store s ON s.s_closed_date_sk = r.cr_returned_date_sk
WHERE r.d_holiday = 'Y'
  AND s.s_county = 'Fairfield County'
GROUP BY r.d_date
UNION ALL
SELECT
    'NonHoliday' AS period_type,
    r.d_date,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM returns_dt r
JOIN store s ON s.s_closed_date_sk = r.cr_returned_date_sk
WHERE r.d_holiday = 'N'
  AND s.s_county = 'Jefferson Davis Parish'
GROUP BY r.d_date
ORDER BY period_type, total_return_amount DESC
LIMIT 100
