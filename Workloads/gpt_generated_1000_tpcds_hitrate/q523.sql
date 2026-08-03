WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss AS net_loss,
        cr.cr_returning_addr_sk,
        cr.cr_returning_customer_sk,
        t.t_shift,
        t.t_time,
        t.t_meal_time,
        CASE
            WHEN cr.cr_net_loss > 0 THEN 'Loss'
            ELSE 'Gain'
        END AS loss_indicator,
        CONCAT('Shift_', t.t_shift) AS shift_label,
        SUM(cr.cr_net_loss) OVER (
            PARTITION BY t.t_shift
            ORDER BY t.t_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_net_loss,
        LAG(cr.cr_net_loss) OVER (
            PARTITION BY t.t_shift
            ORDER BY t.t_time
        ) AS prev_net_loss
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE
        regexp_like(t.t_shift, '^first|second$')
        AND t.t_meal_time LIKE '%breakfast%'
        AND cr.cr_return_amount > (
            SELECT avg(cr_return_amount)
            FROM catalog_returns
        )
        AND cr.cr_returning_addr_sk NOT IN (
            SELECT cr2.cr_returning_addr_sk
            FROM catalog_returns cr2
            WHERE cr2.cr_return_amount > 5000
        )
)
SELECT
    shift_label,
    loss_indicator,
    COUNT(*) AS return_cnt,
    SUM(net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    MAX(running_net_loss) AS max_running_net_loss,
    MIN(prev_net_loss) AS min_prev_net_loss
FROM filtered
GROUP BY shift_label, loss_indicator
ORDER BY total_net_loss DESC
LIMIT 100
