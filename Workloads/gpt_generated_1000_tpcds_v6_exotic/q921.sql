WITH agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        r.r_reason_desc    AS reason_desc,
        td.t_am_pm         AS am_pm,
        COUNT(*)           AS return_cnt,
        SUM(cr.cr_net_loss)          AS total_net_loss,
        AVG(cr.cr_return_amount)     AS avg_return_amount,
        MIN(cr.cr_return_tax)        AS min_return_tax,
        MAX(cr.cr_return_tax)        AS max_return_tax
    FROM catalog_returns cr
    INNER JOIN time_dim td   ON cr.cr_returned_time_sk = td.t_time_sk
    INNER JOIN customer c    ON cr.cr_returning_customer_sk = c.c_customer_sk
    INNER JOIN warehouse w   ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN reason r      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        cr.cr_return_tax      > 10.00
        AND cr.cr_return_amount BETWEEN 20.00 AND 500.00
        AND cr.cr_return_quantity >= 1
        AND cr.cr_fee           < 5.00
        AND r.r_reason_desc    LIKE '%purchase%'
        AND td.t_am_pm         = 'PM'
        AND w.w_state          = 'CA'
        AND c.c_birth_year     = 1985
    GROUP BY
        w.w_warehouse_name,
        r.r_reason_desc,
        td.t_am_pm
    HAVING
        SUM(cr.cr_net_loss) > 1000
        AND COUNT(*) >= 5
)
SELECT
    warehouse_name,
    reason_desc,
    am_pm,
    return_cnt,
    total_net_loss,
    avg_return_amount,
    min_return_tax,
    max_return_tax,
    RANK() OVER (ORDER BY total_net_loss DESC)               AS loss_rank,
    SUM(total_net_loss) OVER (ORDER BY total_net_loss DESC
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
