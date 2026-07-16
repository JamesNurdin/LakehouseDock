SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_city,
    s.s_state,
    w.web_name,
    w.web_city,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns AS cr
JOIN date_dim AS d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics AS cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics AS cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site AS w
    ON w.web_open_date_sk = d.d_date_sk
   AND w.web_close_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_city,
    s.s_state,
    w.web_name,
    w.web_city,
    cd_ref.cd_gender,
    cd_ret.cd_gender
ORDER BY total_net_loss DESC
LIMIT 100
