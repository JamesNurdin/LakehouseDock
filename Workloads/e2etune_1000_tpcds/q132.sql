SELECT
    t.t_hour,
    cd_ret.cd_gender,
    cd_ret.cd_credit_rating,
    wp.wp_type,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_return_quantity), 0) AS avg_return_amount_per_item,
    RANK() OVER (PARTITION BY t.t_hour ORDER BY SUM(wr.wr_return_amt) DESC) AS page_type_rank
FROM web_returns wr
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
WHERE
    t.t_hour BETWEEN 9 AND 18
    AND cd_ret.cd_gender = 'F'
    AND cd_ret.cd_credit_rating IN ('High Risk', 'Low Risk')
    AND cd_ret.cd_dep_college_count >= 1
    AND cd_ref.cd_education_status = 'College'
    AND wp.wp_type IS NOT NULL
GROUP BY
    t.t_hour,
    cd_ret.cd_gender,
    cd_ret.cd_credit_rating,
    wp.wp_type
HAVING
    SUM(wr.wr_return_amt) > 1000
ORDER BY
    t.t_hour,
    total_return_amount DESC
LIMIT 100
