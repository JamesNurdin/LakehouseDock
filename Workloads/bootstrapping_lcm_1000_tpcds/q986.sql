WITH aggregated_returns AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        d_ret.d_year,
        d_ret.d_month_seq,
        format('%s-%02d', d_ret.d_year, d_ret.d_month_seq) AS return_month,
        t.t_hour,
        t.t_meal_time,
        s.s_store_name,
        s.s_city AS store_city,
        d_cc_open.d_year AS cc_open_year,
        d_cc_closed.d_year AS cc_closed_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        SUM(cr.cr_fee) AS total_fee,
        MAX(cr.cr_return_tax) AS max_return_tax,
        MIN(cr.cr_return_tax) AS min_return_tax,
        CASE WHEN SUM(cr.cr_return_quantity) > 0
             THEN SUM(cr.cr_return_amount) / SUM(cr.cr_return_quantity)
             ELSE NULL
        END AS avg_amount_per_quantity
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2022
      AND t.t_hour BETWEEN 9 AND 18
      AND s.s_state = 'CA'
    GROUP BY
        cc.cc_name,
        cc.cc_city,
        d_ret.d_year,
        d_ret.d_month_seq,
        t.t_hour,
        t.t_meal_time,
        s.s_store_name,
        s.s_city,
        d_cc_open.d_year,
        d_cc_closed.d_year
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    ar.*,
    ROW_NUMBER() OVER (
        PARTITION BY ar.d_year, ar.d_month_seq
        ORDER BY ar.total_net_loss DESC
    ) AS net_loss_rank_in_month
FROM aggregated_returns ar
ORDER BY ar.total_net_loss DESC
LIMIT 50
