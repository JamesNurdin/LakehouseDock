WITH joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        wr.wr_order_number,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        d.d_year,
        t.t_hour,
        s.s_state
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
)
SELECT
    d_year,
    s_state,
    CASE
        WHEN t_hour BETWEEN 0 AND 11 THEN 'Morning'
        WHEN t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    COUNT(DISTINCT cr_order_number) AS catalog_orders,
    SUM(cr_net_loss) AS total_catalog_net_loss,
    COUNT(DISTINCT wr_order_number) AS web_orders,
    SUM(wr_net_loss) AS total_web_net_loss,
    SUM(cr_net_loss) - SUM(wr_net_loss) AS net_loss_diff,
    SUM(cr_return_quantity) AS total_catalog_return_qty,
    SUM(wr_return_quantity) AS total_web_return_qty,
    SUM(cr_return_quantity * cr_return_amount) AS total_catalog_return_amount,
    SUM(wr_return_quantity * wr_return_amt) AS total_web_return_amount,
    ROUND(
        (SUM(cr_return_quantity * cr_return_amount) - SUM(wr_return_quantity * wr_return_amt))
        / NULLIF((SUM(cr_return_quantity) + SUM(wr_return_quantity)), 0),
        2
    ) AS avg_return_amount_diff
FROM joined
WHERE d_year BETWEEN 2000 AND 2002
GROUP BY
    d_year,
    s_state,
    CASE
        WHEN t_hour BETWEEN 0 AND 11 THEN 'Morning'
        WHEN t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
HAVING SUM(cr_net_loss) > 0
ORDER BY d_year, s_state, time_of_day
LIMIT 100
