SELECT
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_brand,
    s.s_state,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    (SUM(cr.cr_return_amt_inc_tax) - SUM(cr.cr_return_amount)) / NULLIF(SUM(cr.cr_return_amount), 0) AS avg_tax_rate,
    (SUM(cr.cr_net_loss) / NULLIF(SUM(cr.cr_return_amount), 0)) AS net_loss_ratio,
    (SUM(cr.cr_return_amount) * 0.1) AS ten_percent_of_return_amount
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND cr.cr_net_loss > 0
GROUP BY
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_brand,
    s.s_state,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
HAVING SUM(cr.cr_return_quantity) > 10
ORDER BY d.d_year DESC, total_return_amount DESC
LIMIT 100
