WITH daily_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    LEFT OUTER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_store_credit < 30
      AND d.d_year = 2001
      AND d.d_qoy = 2
    GROUP BY d.d_year, d.d_month_seq
),
yearly_stats AS (
    SELECT
        d_year,
        AVG(total_return_amount) AS avg_monthly_return,
        SUM(total_return_qty) AS total_qty_year,
        SUM(return_cnt) AS total_returns_year
    FROM daily_returns
    GROUP BY d_year
)
SELECT
    y.d_year,
    y.avg_monthly_return,
    y.total_qty_year,
    y.total_returns_year,
    ROW_NUMBER() OVER (ORDER BY y.avg_monthly_return DESC) AS rn
FROM yearly_stats y
WHERE y.total_returns_year > 10
ORDER BY y.avg_monthly_return DESC
LIMIT 100
