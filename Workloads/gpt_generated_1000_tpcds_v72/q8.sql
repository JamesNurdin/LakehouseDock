WITH filtered AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        td.t_hour,
        td.t_am_pm
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_quantity > 1
        AND cr.cr_return_amount > 20
        AND td.t_hour BETWEEN 7 AND 16
        AND cr.cr_returning_hdemo_sk IN (4163, 718, 1206)
        AND cr.cr_returned_time_sk IN (5, 7, 12)
),
agg AS (
    SELECT
        t_hour,
        t_am_pm,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_quantity
    FROM filtered
    GROUP BY t_hour, t_am_pm
)
SELECT
    t_hour,
    t_am_pm,
    total_return_amount,
    total_quantity,
    CASE
        WHEN total_return_amount > 1000 THEN 'High'
        WHEN total_return_amount > 500 THEN 'Medium'
        ELSE 'Low'
    END AS amount_category,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    ROW_NUMBER() OVER (PARTITION BY t_am_pm ORDER BY total_return_amount DESC) AS rn_by_am_pm
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
