WITH high_qty AS (
    SELECT
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_refunded_cash) AS avg_refunded_cash,
        'high_quantity' AS segment
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 10
    GROUP BY r.r_reason_desc
),
high_cash AS (
    SELECT
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_refunded_cash) AS avg_refunded_cash,
        'high_cash' AS segment
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_refunded_cash > 500
    GROUP BY r.r_reason_desc
)
SELECT
    combined.r_reason_desc,
    combined.total_return_amount,
    combined.avg_refunded_cash,
    combined.segment
FROM (
    SELECT r_reason_desc, total_return_amount, avg_refunded_cash, segment FROM high_qty
    UNION ALL
    SELECT r_reason_desc, total_return_amount, avg_refunded_cash, segment FROM high_cash
) AS combined
ORDER BY combined.total_return_amount DESC
LIMIT 20
