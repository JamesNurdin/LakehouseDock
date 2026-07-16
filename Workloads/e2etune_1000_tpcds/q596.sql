WITH filtered_returns AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450900 AND 2451100
      AND cr_return_amount > 0
),
agg_by_reason AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee,
        approx_percentile(cr.cr_return_amount, 0.5) AS median_return_amount,
        SUM(CASE WHEN cr.cr_return_quantity > 1 THEN cr.cr_return_amount ELSE 0 END) AS multi_item_return_amount
    FROM filtered_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
)
SELECT
    r_reason_desc,
    total_returns,
    total_return_amount,
    avg_return_amount,
    total_net_loss,
    avg_fee,
    median_return_amount,
    multi_item_return_amount,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    ROW_NUMBER() OVER (ORDER BY total_returns DESC) AS returns_rank
FROM agg_by_reason
WHERE total_returns >= 5
ORDER BY total_return_amount DESC
LIMIT 15
