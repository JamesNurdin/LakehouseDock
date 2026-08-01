WITH agg AS (
    SELECT
        s.s_state AS store_state,
        cp.cp_department AS department,
        d_wr.d_month_seq AS month_seq,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns
    FROM web_returns wr
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_wr.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_wr.d_date_sk
    WHERE
        d_wr.d_current_week = 'N'
        AND d_wr.d_following_holiday = 'N'
        AND s.s_street_type = 'Ave'
        AND cp.cp_type = 'PROMO'
        AND cp.cp_department = 'Jewelry'
        AND wr.wr_return_amt_inc_tax > 1000
        AND wr.wr_return_quantity > 1
    GROUP BY GROUPING SETS (
        (s.s_state, cp.cp_department, d_wr.d_month_seq),
        (s.s_state, cp.cp_department),
        (s.s_state),
        ()
    )
)
SELECT
    store_state,
    department,
    month_seq,
    total_return_amount,
    total_net_loss,
    total_returns,
    RANK() OVER (PARTITION BY store_state ORDER BY total_return_amount DESC) AS state_return_rank,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY total_net_loss DESC) AS dept_loss_rank,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS overall_return_rownum
FROM agg
ORDER BY
    store_state,
    department,
    month_seq
