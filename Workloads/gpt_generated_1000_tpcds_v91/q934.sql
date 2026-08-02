SELECT
    cc1.cc_name AS call_center_name,
    d_cc_open1.d_year AS open_year,
    d_cc_closed1.d_year AS closed_year,
    d_cr_date.d_year AS return_year,
    t_cr_time.t_meal_time AS meal_time,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 50000 THEN 'HIGH' ELSE 'LOW' END AS loss_severity,
    (
        SELECT SUM(wr2.wr_net_loss)
        FROM web_returns wr2
        JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_cr_date.d_year
    ) AS total_web_net_loss_same_year
FROM
    catalog_returns cr
    JOIN call_center cc1
        ON cr.cr_call_center_sk = cc1.cc_call_center_sk
    JOIN date_dim d_cr_date
        ON cr.cr_returned_date_sk = d_cr_date.d_date_sk
    JOIN time_dim t_cr_time
        ON cr.cr_returned_time_sk = t_cr_time.t_time_sk
    JOIN time_dim t_cr_time2
        ON cr.cr_returned_time_sk = t_cr_time2.t_time_sk
    JOIN date_dim d_cc_open1
        ON cc1.cc_open_date_sk = d_cc_open1.d_date_sk
    JOIN date_dim d_cc_closed1
        ON cc1.cc_closed_date_sk = d_cc_closed1.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_cr_date.d_date_sk
    JOIN time_dim t_wr_time
        ON wr.wr_returned_time_sk = t_wr_time.t_time_sk
    JOIN date_dim d_wr_date2
        ON wr.wr_returned_date_sk = d_wr_date2.d_date_sk
WHERE
    t_cr_time.t_meal_time = 'dinner'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_returned_time_sk = t_cr_time.t_time_sk
          AND cr_sub.cr_return_amount > 200
    )
GROUP BY
    cc1.cc_name,
    d_cc_open1.d_year,
    d_cc_closed1.d_year,
    d_cr_date.d_year,
    t_cr_time.t_meal_time
ORDER BY
    total_catalog_return_amount DESC
