SELECT
    d_ret.d_year,
    d_ret.d_quarter_name,
    s.s_state,
    CASE WHEN s.s_state = 'CA' THEN 'California' ELSE 'Other State' END AS state_group,
    wp.wp_type,
    t.t_meal_time,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_net_loss) / COUNT(*) AS avg_net_loss_per_return,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS num_returns,
    SUM(cr.cr_fee) AS total_fees,
    CASE WHEN SUM(cr.cr_return_amount) > 0 THEN SUM(cr.cr_fee) / SUM(cr.cr_return_amount) ELSE NULL END AS fee_to_return_ratio,
    MIN(t.t_hour) AS earliest_return_hour,
    MAX(t.t_hour) AS latest_return_hour,
    MIN(d_access.d_date) AS earliest_page_access_date,
    MAX(d_access.d_date) AS latest_page_access_date
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_ret.d_year >= 2000
GROUP BY
    d_ret.d_year,
    d_ret.d_quarter_name,
    s.s_state,
    CASE WHEN s.s_state = 'CA' THEN 'California' ELSE 'Other State' END,
    wp.wp_type,
    t.t_meal_time
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
