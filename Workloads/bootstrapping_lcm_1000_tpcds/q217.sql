WITH aggregated_returns AS (
    SELECT
        dd.d_year AS dd_year,
        dd.d_month_seq AS dd_month_seq,
        dd.d_quarter_name AS dd_quarter_name,
        td.t_hour AS t_hour,
        td.t_am_pm AS t_am_pm,
        s.s_store_id AS s_store_id,
        s.s_state AS s_state,
        c_ref.c_customer_id AS refunded_customer_id,
        c_ret.c_customer_id AS returning_customer_id,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(date_diff('day', d_ship.d_date, dd.d_date)) AS avg_days_since_first_ship,
        AVG(date_diff('day', d_sales.d_date, dd.d_date)) AS avg_days_since_first_sales,
        CASE
            WHEN c_ref.c_birth_month BETWEEN 1 AND 3 THEN 'Q1 Birth'
            WHEN c_ref.c_birth_month BETWEEN 4 AND 6 THEN 'Q2 Birth'
            WHEN c_ref.c_birth_month BETWEEN 7 AND 9 THEN 'Q3 Birth'
            ELSE 'Q4 Birth'
        END AS birth_quarter
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
    JOIN date_dim d_ship ON c_ref.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_sales ON c_ref.c_first_sales_date_sk = d_sales.d_date_sk
    WHERE dd.d_year BETWEEN 2000 AND 2005
    GROUP BY
        dd.d_year,
        dd.d_month_seq,
        dd.d_quarter_name,
        td.t_hour,
        td.t_am_pm,
        s.s_store_id,
        s.s_state,
        c_ref.c_customer_id,
        c_ret.c_customer_id,
        CASE
            WHEN c_ref.c_birth_month BETWEEN 1 AND 3 THEN 'Q1 Birth'
            WHEN c_ref.c_birth_month BETWEEN 4 AND 6 THEN 'Q2 Birth'
            WHEN c_ref.c_birth_month BETWEEN 7 AND 9 THEN 'Q3 Birth'
            ELSE 'Q4 Birth'
        END
)
SELECT
    dd_year,
    dd_month_seq,
    dd_quarter_name,
    t_hour,
    t_am_pm,
    s_store_id,
    s_state,
    refunded_customer_id,
    returning_customer_id,
    total_net_loss,
    avg_return_qty,
    return_count,
    total_return_amount,
    avg_days_since_first_ship,
    avg_days_since_first_sales,
    birth_quarter,
    RANK() OVER (PARTITION BY dd_year ORDER BY total_net_loss DESC) AS yearly_store_loss_rank
FROM aggregated_returns
ORDER BY total_net_loss DESC
LIMIT 100
