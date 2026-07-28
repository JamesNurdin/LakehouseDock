WITH joined AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        t.t_shift,
        t.t_sub_shift,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND cp.cp_start_date_sk >= 2451000
      AND cr.cr_return_quantity >= 1
      AND cr.cr_return_amount > 10
      AND t.t_shift = 'first'
      AND t.t_sub_shift = 'morning'
),
dept_agg AS (
    SELECT
        cp_department,
        cp_type,
        t_shift,
        t_sub_shift,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_return_amount,
        SUM(cr_return_quantity) AS total_qty,
        CASE 
            WHEN SUM(cr_net_loss) > 5000 THEN 'High'
            WHEN SUM(cr_net_loss) > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category
    FROM joined
    GROUP BY cp_department, cp_type, t_shift, t_sub_shift
)
SELECT
    loss_category,
    AVG(total_net_loss) AS avg_net_loss,
    SUM(return_cnt) AS total_returns,
    SUM(total_qty) AS total_quantity
FROM dept_agg
GROUP BY loss_category
HAVING AVG(total_net_loss) > 500
ORDER BY avg_net_loss DESC
LIMIT 100
