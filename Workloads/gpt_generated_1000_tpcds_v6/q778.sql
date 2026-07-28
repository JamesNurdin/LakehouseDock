WITH distinct_cr AS (
    SELECT DISTINCT
        cr_order_number,
        cr_reason_sk,
        cr_returned_time_sk,
        cr_refunded_cdemo_sk,
        cr_return_amount,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 15
),
joined AS (
    SELECT
        r.r_reason_desc,
        td.t_am_pm,
        cd.cd_gender,
        COALESCE(distinct_cr.cr_net_loss, 0)            AS cr_net_loss,
        COALESCE(wr.wr_net_loss, 0)                    AS wr_net_loss,
        distinct_cr.cr_order_number                     AS order_number
    FROM distinct_cr
    JOIN reason r
        ON distinct_cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td
        ON distinct_cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON distinct_cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
       AND wr.wr_returned_time_sk = td.t_time_sk
       AND wr.wr_return_quantity > 1
    WHERE td.t_am_pm = 'PM'
      AND cd.cd_gender = 'M'
      AND r.r_reason_id LIKE 'AAAA%'
)
SELECT
    r_reason_desc,
    t_am_pm,
    cd_gender,
    SUM(cr_net_loss + wr_net_loss)                         AS total_net_loss,
    COUNT(DISTINCT order_number)                           AS distinct_orders,
    CASE WHEN SUM(cr_net_loss + wr_net_loss) > 5000
         THEN 'High' ELSE 'Medium' END                    AS loss_category,
    RANK() OVER (PARTITION BY t_am_pm ORDER BY SUM(cr_net_loss + wr_net_loss) DESC) AS loss_rank
FROM joined
GROUP BY r_reason_desc, t_am_pm, cd_gender
HAVING SUM(cr_net_loss + wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 20
