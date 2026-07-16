WITH monthly_store_losses AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq AS month_seq,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        RANK() OVER (PARTITION BY d_ret.d_month_seq ORDER BY SUM(wr.wr_net_loss) DESC) AS month_rank
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2002
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND cd_ref.cd_education_status IN ('College', '4 yr Degree')
      AND s.s_state = 'CA'
      AND ws.web_class = 'Retail'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_id, s.s_store_name, d_ret.d_year, d_ret.d_month_seq
)
SELECT
    month_seq,
    s_store_id,
    s_store_name,
    total_net_loss,
    total_return_amount,
    avg_return_quantity,
    distinct_orders,
    total_refunded_cash,
    month_rank
FROM monthly_store_losses
WHERE month_rank <= 5
ORDER BY month_seq, month_rank
